// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Кумбел';

  @override
  String get splashLoading => 'Загрузка...';

  @override
  String get loginTitle => 'Добро пожаловать';

  @override
  String get loginSubtitle => 'Войдите, чтобы продолжить';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String get signInError => 'Не удалось войти. Попробуйте ещё раз.';

  @override
  String get tabMain => 'Главная';

  @override
  String get tabProfile => 'Профиль';

  @override
  String greeting(String name) {
    return 'Привет, $name!';
  }

  @override
  String get profileTitle => 'Профиль';

  @override
  String get email => 'Почта';

  @override
  String get signOut => 'Выйти';
}
