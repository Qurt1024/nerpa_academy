import 'package:equatable/equatable.dart';

/// Результат прохождения урока (квиза).
///
/// Создаётся после завершения всех вопросов и сохраняется в Firestore:
/// users/{userId}/lessonResults/{resultId}
///
/// Также используется для отображения «Results screen» (TODO в макете).
class LessonResultModel extends Equatable {
  /// Уникальный идентификатор.
  final String id;

  /// ID пользователя.
  final String userId;

  /// ID предмета.
  final String subjectId;

  /// ID урока.
  final String lessonId;

  /// Количество правильных ответов.
  final int correctCount;

  /// Общее количество вопросов.
  final int totalCount;

  /// Сколько жизней (hearts) осталось после прохождения.
  /// Аналогично системе сердечек Duolingo.
  final int heartsRemaining;

  /// Дата и время прохождения.
  final DateTime completedAt;

  const LessonResultModel({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.lessonId,
    required this.correctCount,
    required this.totalCount,
    required this.heartsRemaining,
    required this.completedAt,
  });

  /// Процент правильных ответов (0.0 – 1.0).
  double get accuracy => totalCount == 0 ? 0 : correctCount / totalCount;

  /// Урок пройден успешно (все ответы правильные).
  bool get isPerfect => correctCount == totalCount;

  factory LessonResultModel.fromJson(Map<String, dynamic> json, String docId) {
    return LessonResultModel(
      id: docId,
      userId: json['userId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      lessonId: json['lessonId'] as String? ?? '',
      correctCount: json['correctCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      heartsRemaining: json['heartsRemaining'] as int? ?? 0,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'subjectId': subjectId,
        'lessonId': lessonId,
        'correctCount': correctCount,
        'totalCount': totalCount,
        'heartsRemaining': heartsRemaining,
        'completedAt': completedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        subjectId,
        lessonId,
        correctCount,
        totalCount,
        heartsRemaining,
        completedAt,
      ];
}
