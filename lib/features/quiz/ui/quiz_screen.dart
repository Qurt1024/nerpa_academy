import 'package:flutter/material.dart';

/// Экран квиза.
///
/// Поддерживает два типа вопросов (см. [QuestionType]):
/// 1. [QuestionType.selectOption] — пользователь выбирает один из 4 вариантов.
/// 2. [QuestionType.typeAnswer]   — пользователь вводит ответ в текстовое поле.
///
/// Механика здоровья (health bar):
/// - У пользователя есть N сердечек ([UserModel.hearts]).
/// - При неправильном ответе сердечко теряется.
/// - Если сердечек не осталось — урок заканчивается досрочно.
///
/// По завершении всех вопросов создаётся [LessonResultModel]
/// и сохраняется в Firestore (TODO: results screen).
class QuizScreen extends StatelessWidget {
  final String subjectId;
  final String lessonId;

  const QuizScreen({
    super.key,
    required this.subjectId,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TODO: добавить health bar (hearts) в AppBar
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Text('Quiz for lesson $lessonId — TODO'),
      ),
    );
  }
}
