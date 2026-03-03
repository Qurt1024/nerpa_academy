import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/ui/home_shell.dart';
import '../../features/home/ui/main_tab.dart';
import '../../features/home/ui/profile_tab.dart';
import '../../features/lesson_detail/ui/lesson_detail_screen.dart';
import '../../features/lessons/ui/lessons_screen.dart';
import '../../features/login/ui/login_screen.dart';
import '../../features/quiz/ui/quiz_screen.dart';
import '../../features/signup/ui/sign_up_screen.dart';
import '../../features/signup/ui/subject_picker_screen.dart';
import '../../features/splash/ui/splash_screen.dart';
import 'route_names.dart';

/// Конфигурация навигации (GoRouter).
///
/// Полная структура маршрутов:
/// ```
/// /                              → SplashScreen
/// /login                         → LoginScreen
/// /signup                        → SignUpScreen
/// /signup/subjects               → SubjectPickerScreen
/// /home (ShellRoute)
///   /home/main                   → MainTab
///   /home/profile                → ProfileTab
/// /subjects/:subjectId/lessons              → LessonsScreen
/// /subjects/:subjectId/lessons/:lessonId    → LessonDetailScreen
/// /subjects/:subjectId/lessons/:lessonId/quiz → QuizScreen
/// ```
class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: RouteNames.splash,

      routes: [
        // ── Splash ───────────────────────────────────────────
        GoRoute(
          name: RouteNames.splashName,
          path: RouteNames.splash,
          builder: (context, state) => const SplashScreen(),
        ),

        // ── Login ────────────────────────────────────────────
        GoRoute(
          name: RouteNames.loginName,
          path: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),

        // ── Sign Up 1 → Sign Up 2 (вложенный) ────────────────
        GoRoute(
          name: RouteNames.signupName,
          path: RouteNames.signup,
          builder: (context, state) => const SignUpScreen(),
          routes: [
            GoRoute(
              name: RouteNames.subjectPickerName,
              // Относительный путь от родителя: /signup/subjects
              path: 'subjects',
              builder: (context, state) => const SubjectPickerScreen(),
            ),
          ],
        ),

        // ── Home (ShellRoute + BottomNav) ────────────────────
        ShellRoute(
          builder: (context, state, child) => HomeShell(child: child),
          routes: [
            GoRoute(
              name: RouteNames.mainName,
              path: RouteNames.main,
              builder: (context, state) => const MainTab(),
            ),
            GoRoute(
              name: RouteNames.profileName,
              path: RouteNames.profile,
              builder: (context, state) => const ProfileTab(),
            ),
          ],
        ),

        // ── Lessons list ──────────────────────────────────────
        GoRoute(
          name: RouteNames.lessonsName,
          path: RouteNames.lessons,
          builder: (context, state) {
            final subjectId =
                state.pathParameters[RouteNames.subjectIdParam]!;
            return LessonsScreen(subjectId: subjectId);
          },

          // ── Lesson detail + Quiz (вложены, чтобы кнопка «Назад»
          //    работала корректно) ─────────────────────────────
          routes: [
            GoRoute(
              name: RouteNames.lessonDetailName,
              // Относительный путь: /subjects/:subjectId/lessons/:lessonId
              path: ':${RouteNames.lessonIdParam}',
              builder: (context, state) {
                final subjectId =
                    state.pathParameters[RouteNames.subjectIdParam]!;
                final lessonId =
                    state.pathParameters[RouteNames.lessonIdParam]!;
                return LessonDetailScreen(
                  subjectId: subjectId,
                  lessonId: lessonId,
                );
              },
              routes: [
                GoRoute(
                  name: RouteNames.quizName,
                  // Относительный путь: quiz
                  path: 'quiz',
                  builder: (context, state) {
                    final subjectId =
                        state.pathParameters[RouteNames.subjectIdParam]!;
                    final lessonId =
                        state.pathParameters[RouteNames.lessonIdParam]!;
                    return QuizScreen(
                      subjectId: subjectId,
                      lessonId: lessonId,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],

      // ── Страница ошибки (404) ──────────────────────────────
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text(
            'Page not found: ${state.uri}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
