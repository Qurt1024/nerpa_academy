/// Константы имён коллекций Firestore.
///
/// Структура базы данных:
/// ```
/// users/                          ← профили пользователей
///   {userId}/
///     lessonResults/              ← результаты прохождения уроков
///       {resultId}
///
/// subjects/                       ← учебные предметы
///   {subjectId}/
///     lessons/                    ← уроки предмета
///       {lessonId}/
///         questions/              ← вопросы урока
///           {questionId}
/// ```
class CollectionNames {
  // ── Верхнеуровневые коллекции ─────────────────────────────────
  static const String users = 'users';
  static const String subjects = 'subjects';

  // ── Подколлекции ──────────────────────────────────────────────
  static const String lessons = 'lessons';
  static const String questions = 'questions';
  static const String lessonResults = 'lessonResults';
}
