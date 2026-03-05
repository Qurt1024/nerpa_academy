import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

// ─── Multiplayer Repository ─────────────────────────────────────────────────

class MultiplayerRepository {
  FirebaseDatabase get _rtdb => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: dotenv.env['RTDB_URL']!,
  );
  final _uuid = const Uuid();

  DatabaseReference _roomRef(String roomId) =>
      _rtdb.ref('rooms/$roomId');

  Future<String> createRoom({
    required String hostUid,
    required String subjectId,
    required String lessonId,
    required String displayName,
  }) async {
    final roomId = _uuid.v4().substring(0, 6).toUpperCase();
    final room = RoomModel(
      id: roomId,
      hostUid: hostUid,
      subjectId: subjectId,
      lessonId: lessonId,
      status: RoomStatus.waiting,
      players: [
        RoomPlayer(
          uid: hostUid,
          displayName: displayName,
          isReady: false,
        ),
      ],
      createdAt: DateTime.now(),
    );
    await _roomRef(roomId).set(room.toMap());
    return roomId;
  }

  Future<RoomModel?> joinRoom({
    required String roomId,
    required String uid,
    required String displayName,
  }) async {
    final snap = await _roomRef(roomId).get();
    if (!snap.exists) return null;

    final data = Map<String, dynamic>.from(snap.value as Map);
    final room = RoomModel.fromMap(roomId, data);

    if (room.players.length >= 4) {
      throw Exception('Комната заполнена');
    }
    if (room.status != RoomStatus.waiting) {
      throw Exception('Игра уже началась');
    }

    final player = RoomPlayer(uid: uid, displayName: displayName);
    await _roomRef(roomId)
        .child('players/$uid')
        .set(player.toMap());

    return room.copyWith(players: [...room.players, player]);
  }

  Stream<RoomModel> watchRoom(String roomId) {
    return _roomRef(roomId).onValue.map((event) {
      final data =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      return RoomModel.fromMap(roomId, data);
    });
  }

  Future<void> setPlayerReady(
      String roomId, String uid, bool isReady) async {
    await _roomRef(roomId)
        .child('players/$uid/isReady')
        .set(isReady);
  }

  Future<void> startGame(String roomId) async {
    await _roomRef(roomId).child('status').set('playing');
    await _roomRef(roomId).child('currentQuestionIndex').set(0);
  }

  Future<void> advanceQuestion(
      String roomId, int nextIndex) async {
    await _roomRef(roomId)
        .child('currentQuestionIndex')
        .set(nextIndex);
  }

  Future<void> updatePlayerScore(
      String roomId, String uid, int score) async {
    await _roomRef(roomId)
        .child('players/$uid/score')
        .set(score);
  }

  Future<void> finishGame(String roomId) async {
    await _roomRef(roomId).child('status').set('finished');
  }

  Future<void> leaveRoom(String roomId, String uid) async {
    await _roomRef(roomId).child('players/$uid').remove();
  }
}

extension on RoomModel {
  RoomModel copyWith({List<RoomPlayer>? players}) => RoomModel(
        id: id,
        hostUid: hostUid,
        subjectId: subjectId,
        lessonId: lessonId,
        status: status,
        players: players ?? this.players,
        currentQuestionIndex: currentQuestionIndex,
        createdAt: createdAt,
      );
}

// ─── Chat Repository ────────────────────────────────────────────────────────

class ChatRepository {
  FirebaseDatabase get _rtdb => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: dotenv.env['RTDB_URL']!,
  );

  DatabaseReference _chatRef(String roomId) =>
      _rtdb.ref('chats/$roomId');

  Stream<List<ChatMessage>> watchMessages(String roomId) {
    return _chatRef(roomId)
        .orderByChild('sentAt')
        .limitToLast(100)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];
      final data =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries
          .map((e) => ChatMessage.fromMap(
              e.key, Map<String, dynamic>.from(e.value)))
          .toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderUid,
    required String senderName,
    required String text,
  }) async {
    final truncated =
        text.length > 140 ? text.substring(0, 140) : text;
    final ref = _chatRef(roomId).push();
    await ref.set(ChatMessage(
      id: ref.key!,
      roomId: roomId,
      senderUid: senderUid,
      senderName: senderName,
      text: truncated,
      sentAt: DateTime.now(),
    ).toMap());
  }
}
