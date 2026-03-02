// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kumbel';

  @override
  String get splashLoading => 'Loading...';

  @override
  String get loginTitle => 'Welcome';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInError => 'Sign-in failed. Please try again.';

  @override
  String get tabMain => 'Home';

  @override
  String get tabProfile => 'Profile';

  @override
  String greeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get email => 'Email';

  @override
  String get signOut => 'Sign Out';
}
