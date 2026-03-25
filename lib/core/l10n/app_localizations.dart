// ─── Supported Languages ──────────────────────────────────────────────────────

enum AppLanguage { english, russian, kazakh }

extension AppLanguageExtension on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english: return 'en';
      case AppLanguage.russian: return 'ru';
      case AppLanguage.kazakh: return 'kz';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.english: return 'English';
      case AppLanguage.russian: return 'Русский';
      case AppLanguage.kazakh: return 'Қазақша';
    }
  }

  List<AppLanguage> get learnable =>
      AppLanguage.values.where((l) => l != this).toList();

  String get subjectId {
    switch (this) {
      case AppLanguage.english: return 'language_english';
      case AppLanguage.russian: return 'language_russian';
      case AppLanguage.kazakh: return 'language_kazakh';
    }
  }

  static AppLanguage fromCode(String code) {
    switch (code) {
      case 'ru': return AppLanguage.russian;
      case 'kz': return AppLanguage.kazakh;
      default:   return AppLanguage.english;
    }
  }
}

class AppLocalizations {
  final AppLanguage language;
  const AppLocalizations(this.language);

  String get appName => 'Nerpa Academy';
  String get welcomeSubtitle => _s(en: 'Learn with the Nerpa seal', ru: 'Учись вместе с нерпой', kz: 'Нерпамен бірге оқы');
  String get login => _s(en: 'Log In', ru: 'Войти', kz: 'Кіру');
  String get signUp => _s(en: 'Sign Up', ru: 'Регистрация', kz: 'Тіркелу');
  String get email => _s(en: 'Email', ru: 'Email', kz: 'Email');
  String get password => _s(en: 'Password', ru: 'Пароль', kz: 'Құпиясөз');
  String get confirmPassword => _s(en: 'Confirm Password', ru: 'Подтвердите пароль', kz: 'Құпиясөзді растаңыз');
  String get signInWithGoogle => _s(en: 'Continue with Google', ru: 'Войти через Google', kz: 'Google арқылы кіру');
  String get chooseSubjects => _s(en: 'Choose your subjects!', ru: 'Выберите предметы!', kz: 'Пәндерді таңдаңыз!');
  String get chooseLanguageSubject => _s(en: 'Choose a language to learn', ru: 'Выберите язык для изучения', kz: 'Үйренетін тілді таңдаңыз');
  String get continueText => _s(en: 'Continue', ru: 'Продолжить', kz: 'Жалғастыру');
  String get next => _s(en: 'Next', ru: 'Далее', kz: 'Келесі');
  String get back => _s(en: 'Back', ru: 'Назад', kz: 'Артқа');
  String get step1of2 => _s(en: 'Step 1 of 2', ru: 'Шаг 1 из 2', kz: '1-қадам / 2-ден');
  String get step2of2 => _s(en: 'Step 2 of 2', ru: 'Шаг 2 из 2', kz: '2-қадам / 2-ден');
  String get alreadyHaveAccount => _s(en: 'Already have an account? Log In', ru: 'Уже есть аккаунт? Войти', kz: 'Аккаунтыңыз бар ма? Кіру');
  String get dontHaveAccount => _s(en: "Don't have an account? Sign Up", ru: 'Нет аккаунта? Регистрация', kz: 'Аккаунтыңыз жоқ па? Тіркелу');
  String get selectedHighlighted => _s(en: 'Selected subjects will be highlighted.', ru: 'Выбранные предметы будут выделены.', kz: 'Таңдалған пәндер белгіленеді.');
  String get mySubjects => _s(en: 'My Subjects', ru: 'Мои предметы', kz: 'Менің пәндерім');
  String get study => _s(en: 'Study', ru: 'Учёба', kz: 'Оқу');
  String get play => _s(en: 'Play', ru: 'Играть', kz: 'Ойнау');
  String get profile => _s(en: 'Profile', ru: 'Профиль', kz: 'Профиль');
  String get lessons => _s(en: 'Lessons', ru: 'Уроки', kz: 'Сабақтар');
  String hiUser(String? name) {
    if (name == null || name.isEmpty) return _s(en: 'Hi! 👋', ru: 'Привет! 👋', kz: 'Сәлем! 👋');
    return _s(en: 'Hi, $name! 👋', ru: 'Привет, $name! 👋', kz: 'Сәлем, $name! 👋');
  }
  String get whatAreWeLearning => _s(en: 'What are we learning today?', ru: 'Что учим сегодня?', kz: 'Бүгін не оқимыз?');
  String get noSubjectsYet => _s(en: 'No subjects yet.\nCheck your profile!', ru: 'Предметы не выбраны.\nПроверьте профиль!', kz: 'Пәндер жоқ.\nПрофильді тексеріңіз!');
  String get startLesson => _s(en: 'Start Lesson', ru: 'Начать урок', kz: 'Сабақты бастау');
  String get nextQuestion => _s(en: 'Next', ru: 'Далее', kz: 'Келесі');
  String get yourAnswer => _s(en: 'Type your answer...', ru: 'Введите ответ...', kz: 'Жауапты жазыңыз...');
  String get lessonResults => _s(en: 'Lesson Results', ru: 'Результаты урока', kz: 'Сабақ нәтижелері');
  String get correct => _s(en: 'Correct!', ru: 'Правильно!', kz: 'Дұрыс!');
  String get incorrect => _s(en: 'Incorrect', ru: 'Неверно', kz: 'Қате');
  String get noLessonsAvailable => _s(en: 'No lessons available yet.', ru: 'Уроков пока нет.', kz: 'Сабақтар жоқ.');
  String get createRoom => _s(en: 'Create Room', ru: 'Создать комнату', kz: 'Бөлме жасау');
  String get joinRoom => _s(en: 'Join Room', ru: 'Войти в комнату', kz: 'Бөлмеге кіру');
  String get roomCode => _s(en: 'Room Code', ru: 'Код комнаты', kz: 'Бөлме коды');
  String get players => _s(en: 'Players', ru: 'Игроки', kz: 'Ойыншылар');
  String get ready => _s(en: 'Ready!', ru: 'Готов!', kz: 'Дайын!');
  String get startGame => _s(en: 'Start Game', ru: 'Начать игру', kz: 'Ойынды бастау');
  String get leaderboard => _s(en: 'Leaderboard', ru: 'Таблица лидеров', kz: 'Үздіктер тізімі');
  String get totalScore => _s(en: 'Total Score', ru: 'Всего баллов', kz: 'Жалпы балл');
  String get subjectsSelected => _s(en: 'Subjects Selected', ru: 'Выбранные предметы', kz: 'Таңдалған пәндер');
  String get completedLessonsLabel => _s(en: 'Completed Lessons', ru: 'Пройденные уроки', kz: 'Аяқталған сабақтар');
  String get appLanguageLabel => _s(en: 'App Language', ru: 'Язык приложения', kz: 'Қолданба тілі');
  String get signOut => _s(en: 'Sign Out', ru: 'Выйти', kz: 'Шығу');
  String get editSubjects => _s(en: 'Edit Subjects', ru: 'Изменить предметы', kz: 'Пәндерді өзгерту');
  String get deleteAccount => _s(en: 'Delete Account', ru: 'Удалить аккаунт', kz: 'Аккаунтты жою');
  String get deleteAccountConfirmTitle => _s(en: 'Delete Account?', ru: 'Удалить аккаунт?', kz: 'Аккаунтты жоясыз ба?');
  String get deleteAccountConfirmBody => _s(
    en: 'This will permanently delete your account, progress, and all data. This cannot be undone.',
    ru: 'Это навсегда удалит ваш аккаунт, прогресс и все данные. Это действие нельзя отменить.',
    kz: 'Бұл сіздің аккаунтыңызды, прогресіңізді және барлық деректеріңізді біржола жояды. Бұл әрекетті болдырмау мүмкін емес.',
  );
  String get deleteAccountError => _s(
    en: 'Could not delete account. Please sign out and sign in again, then try again.',
    ru: 'Не удалось удалить аккаунт. Выйдите и войдите снова, затем попробуйте ещё раз.',
    kz: 'Аккаунтты жою мүмкін болмады. Шығып, қайта кіріңіз де, қайта көріңіз.',
  );
  String get typeMessage => _s(en: 'Type a message...', ru: 'Сообщение...', kz: 'Хабарлама жазыңыз...');
  String get send => _s(en: 'Send', ru: 'Отправить', kz: 'Жіберу');
  String get invalidEmail => _s(en: 'Please enter a valid email', ru: 'Введите корректный email', kz: 'Дұрыс email енгізіңіз');
  String get weakPassword => _s(en: 'Password must be at least 6 characters', ru: 'Пароль — минимум 6 символов', kz: 'Құпиясөз кемінде 6 таңба');
  String get passwordsMismatch => _s(en: 'Passwords do not match', ru: 'Пароли не совпадают', kz: 'Құпиясөздер сәйкес емес');
  String get selectSubject => _s(en: 'Please select at least one subject', ru: 'Выберите хотя бы один предмет', kz: 'Кемінде бір пән таңдаңыз');
  String get connectionError => _s(en: 'No internet connection', ru: 'Нет подключения к сети', kz: 'Интернет жоқ');
  String get unknownError => _s(en: 'Something went wrong', ru: 'Что-то пошло не так', kz: 'Қате орын алды');
  String get retry => _s(en: 'Retry', ru: 'Повторить', kz: 'Қайталау');
  String get couldNotLoadSubjects => _s(en: 'Could not load subjects.\nCheck your connection.', ru: 'Не удалось загрузить предметы.\nПроверьте соединение.', kz: 'Пәндерді жүктеу мүмкін болмады.\nБайланысты тексеріңіз.');

  String languageSubjectName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.english: return _s(en: 'English Language', ru: 'Английский язык', kz: 'Ағылшын тілі');
      case AppLanguage.russian: return _s(en: 'Russian Language', ru: 'Русский язык', kz: 'Орыс тілі');
      case AppLanguage.kazakh: return _s(en: 'Kazakh Language', ru: 'Казахский язык', kz: 'Қазақ тілі');
    }
  }

  String mapFirebaseError(String error) {
    if (error.contains('user-not-found') || error.contains('wrong-password') || error.contains('invalid-credential')) {
      return _s(en: 'Invalid email or password', ru: 'Неверный email или пароль', kz: 'Email немесе құпиясөз қате');
    }
    if (error.contains('email-already-in-use')) {
      return _s(en: 'This email is already registered', ru: 'Этот email уже используется', kz: 'Бұл email тіркелген');
    }
    if (error.contains('network-request-failed')) return connectionError;
    return unknownError;
  }

  /// Inline translation helper for one-off strings.
  /// Use named getters for strings used in multiple places.
  String tr({required String en, required String ru, required String kz}) {
    switch (language) {
      case AppLanguage.english: return en;
      case AppLanguage.russian: return ru;
      case AppLanguage.kazakh: return kz;
    }
  }

  // Keep _s as a private alias so existing internal calls still compile
  String _s({required String en, required String ru, required String kz}) =>
      tr(en: en, ru: ru, kz: kz);
}
