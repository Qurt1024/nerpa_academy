import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color skyBlue = Color(0xFF29B6F6);
  static const Color skyBlueDark = Color(0xFF0288D1);
  static const Color skyBlueLight = Color(0xFFB3E5FC);
  static const Color skyBlueSurface = Color(0xFFE1F5FE);

  static const Color white = Color(0xFFFFFFFF);
  static const Color scaffold = Color(0xFFF5F9FF);
  static const Color darkBackground = Color(0xFF1A1D2E);

  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);

  static const Color heartFull = Color(0xFFEF4444);
  static const Color heartEmpty = Color(0xFFE5E7EB);

  static const Color answerCorrect = Color(0xFF4CAF50);
  static const Color answerWrong = Color(0xFFF44336);
  static const Color answerSelected = Color(0xFF29B6F6);
  static const Color answerDefault = Color(0xFFFFFFFF);

  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
}

class AppStrings {
  AppStrings._();

  static const String appName = 'Nerpa Academy';

  // Auth
  static const String welcome = 'Welcome!';
  static const String welcomeSubtitle = 'Learn with the Nerpa seal';
  static const String login = 'Log In';
  static const String signUp = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String signInWithGoogle = 'Continue with Google';
  static const String chooseSubjects = 'Choose your subjects!';
  static const String continueText = 'Continue';
  static const String next = 'Next';
  static const String back = 'Back';

  // Home
  static const String mySubjects = 'My Subjects';
  static const String lessons = 'Lessons';
  static const String profile = 'Profile';
  static const String multiplayer = 'Play';

  // Lessons
  static const String startLesson = 'Start Lesson';
  static const String nextQuestion = 'Next';
  static const String yourAnswer = 'Type your answer...';
  static const String lessonResults = 'Lesson Results';
  static const String correct = 'Correct!';
  static const String incorrect = 'Incorrect';
  static const String score = 'Score';

  // Multiplayer
  static const String createRoom = 'Create Room';
  static const String joinRoom = 'Join Room';
  static const String roomCode = 'Room Code';
  static const String players = 'Players';
  static const String ready = 'Ready!';
  static const String startGame = 'Start Game';
  static const String leaderboard = 'Leaderboard';

  // Chat
  static const String typeMessage = 'Type a message...';
  static const String send = 'Send';

  // Errors
  static const String invalidEmail = 'Please enter a valid email';
  static const String weakPassword = 'Password must be at least 6 characters';
  static const String passwordsMismatch = 'Passwords do not match';
  static const String selectSubject = 'Please select at least one subject';
  static const String connectionError = 'No internet connection';
  static const String unknownError = 'Something went wrong';
}

class AppDimens {
  AppDimens._();

  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 100.0;

  static const double buttonHeight = 52.0;
  static const double minTouchTarget = 48.0;

  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;

  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
}
