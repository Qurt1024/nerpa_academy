/// Константы имён и путей маршрутов.
///
/// Полная структура навигации (соответствует макету):
/// ```
/// /                         → SplashScreen
/// /login                    → LoginScreen
/// /signup                   → SignUpScreen        (Sign Up 1)
/// /signup/subjects          → SubjectPickerScreen (Sign Up 2 — выбор предметов)
///
/// /home/main                → MainTab             (список предметов)
/// /home/profile             → ProfileTab
///
/// /subjects/:subjectId/lessons              → LessonsScreen  (список уроков)
/// /subjects/:subjectId/lessons/:lessonId    → LessonDetailScreen (теория + «Start lesson»)
/// /subjects/:subjectId/lessons/:lessonId/quiz → QuizScreen   (квиз)
/// ```
class RouteNames {
  // ── Пути ─────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';

  /// Sign Up 1: ввод email + пароля.
  static const String signup = '/signup';

  /// Sign Up 2: выбор предметов (вложен в /signup для прогресса назад).
  static const String subjectPicker = '/signup/subjects';

  /// Главная вкладка — список предметов пользователя.
  static const String main = '/home/main';

  /// Вкладка профиля.
  static const String profile = '/home/profile';

  /// Список уроков предмета.
  /// Параметр пути: [subjectIdParam].
  static const String lessons = '/subjects/:subjectId/lessons';

  /// Экран теории + кнопка «Start lesson».
  /// Параметры пути: [subjectIdParam], [lessonIdParam].
  static const String lessonDetail =
      '/subjects/:subjectId/lessons/:lessonId';

  /// Экран квиза.
  /// Параметры пути: [subjectIdParam], [lessonIdParam].
  static const String quiz =
      '/subjects/:subjectId/lessons/:lessonId/quiz';

  // ── Имена (name: ...) для context.goNamed() ──────────────────
  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String signupName = 'signup';
  static const String subjectPickerName = 'subjectPicker';
  static const String mainName = 'main';
  static const String profileName = 'profile';
  static const String lessonsName = 'lessons';
  static const String lessonDetailName = 'lessonDetail';
  static const String quizName = 'quiz';

  // ── Имена параметров пути ─────────────────────────────────────
  static const String subjectIdParam = 'subjectId';
  static const String lessonIdParam = 'lessonId';
}
