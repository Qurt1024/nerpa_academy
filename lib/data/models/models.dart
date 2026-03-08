// ─── User Model ────────────────────────────────────────────────────────────

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final List<String> selectedSubjectIds;
  final List<String> completedLessons;
  final int totalScore;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.selectedSubjectIds = const [],
    this.completedLessons = const [],
    this.totalScore = 0,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      selectedSubjectIds:
          List<String>.from(map['selectedSubjectIds'] ?? []),
      completedLessons:
          List<String>.from(map['completedLessons'] ?? []),
      totalScore: (map['totalScore'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'selectedSubjectIds': selectedSubjectIds,
        'completedLessons': completedLessons,
        'totalScore': totalScore,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    List<String>? selectedSubjectIds,
    List<String>? completedLessons,
    int? totalScore,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        selectedSubjectIds: selectedSubjectIds ?? this.selectedSubjectIds,
        completedLessons: completedLessons ?? this.completedLessons,
        totalScore: totalScore ?? this.totalScore,
        createdAt: createdAt,
      );
}

// ─── Subject Model ──────────────────────────────────────────────────────────

class SubjectModel {
  final String id;
  final String title;
  final String emoji;
  final String colorHex;
  final int lessonCount;
  final int order;

  const SubjectModel({
    required this.id,
    required this.title,
    required this.emoji,
    required this.colorHex,
    required this.lessonCount,
    required this.order,
  });

  factory SubjectModel.fromMap(String id, Map<String, dynamic> map) {
    return SubjectModel(
      id: id,
      title: map['title'] as String? ?? 'Untitled',
      emoji: map['emoji'] as String? ?? '📚',
      colorHex: map['colorHex'] as String? ?? '#29B6F6',
      lessonCount: (map['lessonCount'] as num?)?.toInt() ?? 0,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'emoji': emoji,
        'colorHex': colorHex,
        'lessonCount': lessonCount,
        'order': order,
      };
}

// ─── Lesson Model ───────────────────────────────────────────────────────────

class LessonModel {
  final String id;
  final String subjectId;
  final String title;
  final String? theoryText;
  final String? imageUrl;
  final int order;
  final bool hasTheory;

  const LessonModel({
    required this.id,
    required this.subjectId,
    required this.title,
    this.theoryText,
    this.imageUrl,
    required this.order,
    this.hasTheory = false,
  });

  factory LessonModel.fromMap(String id, Map<String, dynamic> map) {
    return LessonModel(
      id: id,
      subjectId: map['subjectId'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled',
      theoryText: map['theoryText'] as String?,
      imageUrl: map['imageUrl'] as String?,
      order: (map['order'] as num?)?.toInt() ?? 0,
      hasTheory: map['hasTheory'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'subjectId': subjectId,
        'title': title,
        'theoryText': theoryText,
        'imageUrl': imageUrl,
        'order': order,
        'hasTheory': hasTheory,
      };
}

// ─── Question Model ─────────────────────────────────────────────────────────

enum QuestionType { multipleChoice, freeInput }

class QuestionModel {
  final String id;
  final String lessonId;
  final String questionText;
  final QuestionType type;
  final List<String> options; // for MCQ
  final String correctAnswer;
  final int order;
  final String? imageUrl;

  const QuestionModel({
    required this.id,
    required this.lessonId,
    required this.questionText,
    required this.type,
    this.options = const [],
    required this.correctAnswer,
    required this.order,
    this.imageUrl,
  });

  factory QuestionModel.fromMap(String id, Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'multipleChoice';
    final options = List<String>.from(map['options'] ?? []);
    final correctIndex = (map['correctOptionIndex'] as num?)?.toInt();
    final correctAnswer = map['correctAnswer'] as String? ??
        (correctIndex != null && correctIndex < options.length
            ? options[correctIndex]
            : '');
    return QuestionModel(
      id: id,
      lessonId: map['lessonId'] as String? ?? '',
      questionText: map['questionText'] as String? ?? '',
      type: typeStr == 'freeInput'
          ? QuestionType.freeInput
          : QuestionType.multipleChoice,
      options: options,
      correctAnswer: correctAnswer,
      order: (map['order'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'lessonId': lessonId,
        'questionText': questionText,
        'type': type == QuestionType.freeInput ? 'freeInput' : 'multipleChoice',
        'options': options,
        'correctAnswer': correctAnswer,
        'order': order,
        'imageUrl': imageUrl,
      };

  bool checkAnswer(String answer) =>
      answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
}

// ─── Room Model ─────────────────────────────────────────────────────────────

enum RoomStatus { waiting, playing, finished }

class RoomPlayer {
  final String uid;
  final String displayName;
  final bool isReady;
  final int score;

  const RoomPlayer({
    required this.uid,
    required this.displayName,
    this.isReady = false,
    this.score = 0,
  });

  factory RoomPlayer.fromMap(Map<String, dynamic> map) => RoomPlayer(
        uid: map['uid'] as String,
        displayName: map['displayName'] as String? ?? 'Игрок',
        isReady: map['isReady'] as bool? ?? false,
        score: (map['score'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'isReady': isReady,
        'score': score,
      };

  RoomPlayer copyWith({bool? isReady, int? score}) => RoomPlayer(
        uid: uid,
        displayName: displayName,
        isReady: isReady ?? this.isReady,
        score: score ?? this.score,
      );
}

class RoomModel {
  final String id;
  final String hostUid;
  final String subjectId;
  final String lessonId;
  final RoomStatus status;
  final List<RoomPlayer> players;
  final int currentQuestionIndex;
  final DateTime createdAt;

  const RoomModel({
    required this.id,
    required this.hostUid,
    required this.subjectId,
    required this.lessonId,
    required this.status,
    required this.players,
    this.currentQuestionIndex = 0,
    required this.createdAt,
  });

  factory RoomModel.fromMap(String id, Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'waiting';
    return RoomModel(
      id: id,
      hostUid: map['hostUid'] as String,
      subjectId: map['subjectId'] as String? ?? '',
      lessonId: map['lessonId'] as String? ?? '',
      status: statusStr == 'playing'
          ? RoomStatus.playing
          : statusStr == 'finished'
              ? RoomStatus.finished
              : RoomStatus.waiting,
      players: (map['players'] as Map<dynamic, dynamic>?)
              ?.values
              .map((e) => RoomPlayer.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      currentQuestionIndex:
          (map['currentQuestionIndex'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'hostUid': hostUid,
        'subjectId': subjectId,
        'lessonId': lessonId,
        'status': status == RoomStatus.playing
            ? 'playing'
            : status == RoomStatus.finished
                ? 'finished'
                : 'waiting',
        'players': {for (var p in players) p.uid: p.toMap()},
        'currentQuestionIndex': currentQuestionIndex,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}

// ─── Chat Message Model ─────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String roomId;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        roomId: map['roomId'] as String? ?? '',
        senderUid: map['senderUid'] as String,
        senderName: map['senderName'] as String? ?? 'Игрок',
        text: map['text'] as String,
        sentAt: DateTime.fromMillisecondsSinceEpoch(
          (map['sentAt'] as int?) ?? 0,
        ),
      );

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'senderUid': senderUid,
        'senderName': senderName,
        'text': text,
        'sentAt': sentAt.millisecondsSinceEpoch,
      };
}
