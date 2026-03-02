import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/logger.dart';

/// Обёртка над [FirebaseAuth] и [GoogleSignIn].

class FirebaseAuthService {
  /// Экземпляр FirebaseAuth (работа с авторизацией).
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // ── Текущий пользователь ─────────────────────────────────────

  /// Текущий авторизованный пользователь (или `null`).
  User? get currentUser => _auth.currentUser;

  /// Стрим изменений состояния авторизации.
  ///
  /// Каждый раз, когда пользователь входит или выходит,
  /// стрим отправляет новый [User?].
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Вход через Google ────────────────────────────────────────

  /// Запускает флоу входа через Google.
  ///
  /// Возвращает [UserCredential] при успехе или `null`,
  /// если пользователь отменил выбор аккаунта.
  Future<UserCredential?> signInWithGoogle() async {
  try {

    await GoogleSignIn.instance.initialize(
      serverClientId: '798023548630-nbma0k2asoh4nku95m4kmhh3524e77k5.apps.googleusercontent.com',
    );

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication; // ← make sure await is here

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);

    AppLogger.info('Google Sign-In: успешный вход — ${userCredential.user?.email}');
    return userCredential;

  } catch (error, stackTrace) {
    AppLogger.error('Google Sign-In: ошибка входа', error: error, stackTrace: stackTrace);
    rethrow;
  }
}

  // ── Выход ────────────────────────────────────────────────────

  /// Выход из Firebase и Google.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      AppLogger.info('Sign Out: пользователь вышел');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Sign Out: ошибка при выходе',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
