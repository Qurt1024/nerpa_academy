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
  final String title;           // English fallback (always populated)
  final Map<String, String> titles; // {en, ru, kz} localised names
  final String emoji;
  final String colorHex;
  final int lessonCount;
  final int order;

  const SubjectModel({
    required this.id,
    required this.title,
    this.titles = const {},
    required this.emoji,
    required this.colorHex,
    required this.lessonCount,
    required this.order,
  });

  /// Returns the localised title for [langCode], falling back to English.
  String localTitle(String langCode) =>
      titles[langCode] ?? titles['en'] ?? title;

  factory SubjectModel.fromMap(String id, Map<String, dynamic> map) {
    // Read multilingual titles map if present
    final rawTitles = map['titles'];
    final titlesMap = rawTitles is Map
        ? Map<String, String>.fromEntries(
            rawTitles.entries.map((e) => MapEntry(e.key.toString(), e.value.toString())))
        : <String, String>{};

    // English title: prefer titles.en, fall back to legacy 'title' field
    final enTitle = titlesMap['en'] ?? map['title'] as String? ?? 'Untitled';

    return SubjectModel(
      id: id,
      title: enTitle,
      titles: titlesMap,
      emoji: map['emoji'] as String? ?? '📚',
      colorHex: map['colorHex'] as String? ?? '#29B6F6',
      lessonCount: (map['lessonCount'] as num?)?.toInt() ?? 0,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'titles': titles,
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

  factory LessonModel.fromMap(String id, Map<String, dynamic> map, {String langCode = 'en'}) {
    // Support multilingual 'theoryTexts' map, 'theory' (EN fallback), or legacy 'theoryText'
    String? theoryText;
    final theoryTexts = map['theoryTexts'];
    if (theoryTexts is Map) {
      theoryText = theoryTexts[langCode] as String? ?? theoryTexts['en'] as String?;
    }
    theoryText ??= map['theory'] as String? ?? map['theoryText'] as String?;

    // Support multilingual 'titles' map or legacy 'title'
    String title = 'Untitled';
    final titles = map['titles'];
    if (titles is Map) {
      title = titles[langCode] as String? ?? titles['en'] as String? ?? 'Untitled';
    } else {
      title = map['title'] as String? ?? 'Untitled';
    }

    return LessonModel(
      id: id,
      subjectId: map['subjectId'] as String? ?? '',
      title: title,
      theoryText: theoryText,
      imageUrl: map['imageUrl'] as String?,
      order: (map['order'] as num?)?.toInt() ?? 0,
      // Auto-derive: show theory screen whenever there is theory text
      hasTheory: theoryText != null && theoryText.trim().isNotEmpty,
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

  factory QuestionModel.fromMap(String id, Map<String, dynamic> map, {String langCode = 'en'}) {
    // ── type ──────────────────────────────────────────────────────────────────
    final typeStr = map['type'] as String? ?? 'multipleChoice';
    final isFree = typeStr == 'freeInput' || typeStr == 'free_input';

    // ── question text ─────────────────────────────────────────────────────────
    String questionText = '';
    final qTexts = map['questionTexts'];
    if (qTexts is Map) {
      questionText = qTexts[langCode] as String? ?? qTexts['en'] as String? ?? '';
    }
    if (questionText.isEmpty) {
      questionText = map['questionText'] as String? ?? '';
    }

    // ── options ───────────────────────────────────────────────────────────────
    List<String> options = [];
    final optSets = map['optionSets'];
    if (optSets is Map) {
      final rawOpts = optSets[langCode] ?? optSets['en'];
      if (rawOpts is List) options = List<String>.from(rawOpts);
    }
    if (options.isEmpty) {
      options = List<String>.from(map['options'] ?? []);
    }

    // ── correct answer ────────────────────────────────────────────────────────
    String correctAnswer = '';
    final corrAnswers = map['correctAnswers'];
    if (corrAnswers is Map) {
      correctAnswer = corrAnswers[langCode] as String? ?? corrAnswers['en'] as String? ?? '';
    }
    if (correctAnswer.isEmpty) {
      final correctIndex = (map['correctOptionIndex'] as num?)?.toInt();
      correctAnswer = map['correctAnswer'] as String? ??
          (correctIndex != null && correctIndex < options.length
              ? options[correctIndex]
              : '');
    }

    return QuestionModel(
      id: id,
      lessonId: map['lessonId'] as String? ?? '',
      questionText: questionText,
      type: isFree ? QuestionType.freeInput : QuestionType.multipleChoice,
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
