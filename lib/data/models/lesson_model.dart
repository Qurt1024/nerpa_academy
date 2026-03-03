import 'package:equatable/equatable.dart';

/// Модель урока внутри предмета.
///
/// Уроки хранятся в подколлекции:
/// subjects/{subjectId}/lessons/{lessonId}
///
/// Каждый урок может содержать:
/// - теоретический блок (если [theoryText] непустой) — показывается
///   экраном «Class theme» до начала вопросов;
/// - список вопросов ([questions]) — квиз.
class LessonModel extends Equatable {
  /// Уникальный идентификатор документа.
  final String id;

  /// ID предмета-родителя.
  final String subjectId;

  /// Название урока (например, «Lesson 1»).
  final String title;

  /// Порядок урока внутри предмета.
  final int order;

  /// Теоретический текст, который показывается перед вопросами.
  /// Если пустой — экран с теорией пропускается.
  final String theoryText;

  /// URL изображения для экрана теории (необязательно).
  final String theoryImageUrl;

  const LessonModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.order,
    this.theoryText = '',
    this.theoryImageUrl = '',
  });

  bool get hasTheory => theoryText.isNotEmpty;

  factory LessonModel.fromJson(
    Map<String, dynamic> json,
    String docId,
    String subjectId,
  ) {
    return LessonModel(
      id: docId,
      subjectId: subjectId,
      title: json['title'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      theoryText: json['theoryText'] as String? ?? '',
      theoryImageUrl: json['theoryImageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'title': title,
        'order': order,
        'theoryText': theoryText,
        'theoryImageUrl': theoryImageUrl,
      };

  @override
  List<Object?> get props => [id, subjectId, title, order, theoryText, theoryImageUrl];
}
