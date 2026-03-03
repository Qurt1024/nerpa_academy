import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';

/// Экран выбора предметов — Sign Up 2.
///
/// Отображает список всех предметов из Firestore.
/// Выбранные предметы подсвечиваются (синяя кнопка),
/// невыбранные — полупрозрачные (согласно макету).
///
/// После нажатия «Continue» сохраняет [selectedSubjectIds]
/// в профиль пользователя и переходит на [MainTab].
class SubjectPickerScreen extends StatelessWidget {
  const SubjectPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('Choose your subjects! — TODO'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => context.go(RouteNames.main),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
