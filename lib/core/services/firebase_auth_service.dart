import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/logger.dart';

/// Обёртка над [FirebaseAuth] и [GoogleSignIn].
///
/// Совместима с google_sign_in ^7.0.
///
/// Ключевые изменения API в v7 vs v6:
/// - GoogleSignIn() конструктор удалён → используем GoogleSignIn.instance
/// - signIn()       удалён → authenticate()
/// - isSignedIn()   удалён → управляем состоянием вручную
/// - signInSilently() удалён → attemptLightweightAuthentication()
/// - googleUser.authentication стал синхронным (без await)
/// - Требуется явный вызов GoogleSignIn.instance.initialize() перед использованием
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // v7: используем синглтон GoogleSignIn.instance, не конструктор GoogleSignIn()
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isGoogleSignInInitialized = false;

  // ── Инициализация ─────────────────────────────────────────────

  /// Инициализирует GoogleSignIn. Вызывать перед первым использованием.
  /// serverClientId нужен для получения idToken на Android.
  Future<void> _ensureInitialized() async {
    if (_isGoogleSignInInitialized) return;
    try {
      await _googleSignIn.initialize(
        serverClientId:
            '798023548630-nbma0k2asoh4nku95m4kmhh3524e77k5.apps.googleusercontent.com',
      );
      _isGoogleSignInInitialized = true;
      AppLogger.info('FirebaseAuthService: GoogleSignIn initialized');
    } catch (e, st) {
      AppLogger.error('FirebaseAuthService: GoogleSignIn init error',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Текущий пользователь ─────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email + Password ─────────────────────────────────────────

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      AppLogger.info('FirebaseAuth: register — ${cred.user?.email}');
      return cred;
    } on FirebaseAuthException catch (e, st) {
      AppLogger.error('FirebaseAuth: register error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      AppLogger.info('FirebaseAuth: login — ${cred.user?.email}');
      return cred;
    } on FirebaseAuthException catch (e, st) {
      AppLogger.error('FirebaseAuth: login error', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────

  /// Запускает флоу входа через Google и возвращает [UserCredential].
  ///
  /// В v7:
  /// - authenticate() выбрасывает исключение вместо возврата null при отмене.
  ///   Ловим [GoogleSignInException] с кодом canceled.
  /// - account.authentication теперь синхронный (без await).
  /// - idToken получаем через authorizationClient для Firebase.
  Future<UserCredential?> signInWithGoogle() async {
    await _ensureInitialized();

    try {
      // v7: authenticate() вместо signIn()
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // v7: authentication теперь синхронный
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Получаем idToken через authorizationClient для Firebase
      final GoogleSignInClientAuthorization? authorization =
    await googleUser.authorizationClient.authorizationForScopes(['email']);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: authorization?.accessToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      AppLogger.info(
          'Google Sign-In: success — ${userCredential.user?.email}');
      return userCredential;
    } on GoogleSignInException catch (e) {
      // Пользователь нажал «Отмена» или другая ошибка Google
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLogger.info('Google Sign-In: cancelled by user');
        return null;
      }
      AppLogger.error('Google Sign-In: error code=${e.code.name}', error: e);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('Google Sign-In: unexpected error',
          error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Тихий вход (без UI) — используется при восстановлении сессии.
  Future<UserCredential?> signInSilently() async {
    await _ensureInitialized();
    try {
      // v7: attemptLightweightAuthentication() вместо signInSilently()
      final result = _googleSignIn.attemptLightweightAuthentication();
      final GoogleSignInAccount? googleUser =
          result is Future ? await result : result as GoogleSignInAccount?;

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (_) {
      // Тихий вход не удался — это нормально, просто возвращаем null
      return null;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      // v7: нет isSignedIn() — просто вызываем signOut() напрямую,
      // он безопасно обрабатывает случай когда пользователь не вошёл
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      AppLogger.info('FirebaseAuth: signed out');
    } catch (error, stackTrace) {
      AppLogger.error('FirebaseAuth: sign out error',
          error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ── Password Reset ────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e, st) {
      AppLogger.error('FirebaseAuth: reset error', error: e, stackTrace: st);
      rethrow;
    }
  }
}
