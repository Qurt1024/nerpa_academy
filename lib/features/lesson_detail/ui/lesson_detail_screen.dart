import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';

/// Экран теории урока («Class theme»).
///
/// Показывается только если [LessonModel.hasTheory] == true.
/// Если теории нет — роутер сразу перенаправляет на [QuizScreen].
///
/// Содержимое:
/// - Заголовок («Class theme»)
/// - Текст теории
/// - Иллюстрация (изображение тюленя в макете)
/// - Кнопка «Start lesson» → переходит на [QuizScreen]
class LessonDetailScreen extends StatelessWidget {
  final String subjectId;
  final String lessonId;

  const LessonDetailScreen({
    super.key,
    required this.subjectId,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('Class theme — theory text — TODO'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => context.goNamed(
                RouteNames.quizName,
                pathParameters: {
                  RouteNames.subjectIdParam: subjectId,
                  RouteNames.lessonIdParam: lessonId,
                },
              ),
              child: const Text('Start lesson'),
            ),
          ),
        ],
      ),
    );
  }
}
