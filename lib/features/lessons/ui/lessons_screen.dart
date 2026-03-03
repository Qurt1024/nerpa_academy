import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';

/// Экран списка уроков предмета.
///
/// Показывает уроки в виде кнопок (Lesson 1, Lesson 2 …).
/// При нажатии переходит на [LessonDetailScreen].
///
/// В шапке (AppBar) отображается иконка «здоровья» (hearts) —
/// аналог системы Duolingo: при ошибке в квизе кол-во сердечек уменьшается.
class LessonsScreen extends StatelessWidget {
  final String subjectId;

  const LessonsScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        // TODO: добавить health bar (hearts) в AppBar
      ),
      body: Center(
        child: Text('Lessons for subject $subjectId — TODO'),
      ),
    );
  }
}
