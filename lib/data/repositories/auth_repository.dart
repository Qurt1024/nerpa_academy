import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/firebase_auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

/// Репозиторий авторизации — координирует Auth + Firestore.
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel get currentUser {
    final User? firebaseUser = _authService.currentUser;
    if (firebaseUser == null) return UserModel.empty;
    return UserModel.fromFirebaseUser(firebaseUser);
  }

  bool get isLoggedIn => _authService.currentUser != null;

  Stream<UserModel> get authStateChanges {
    return _authService.authStateChanges.map((User? firebaseUser) {
      if (firebaseUser == null) return UserModel.empty;
      return UserModel.fromFirebaseUser(firebaseUser);
    });
  }

  // ── Email + Password ─────────────────────────────────────────

  /// Регистрация через email + пароль.
  /// После регистрации создаёт/обновляет профиль в Firestore.
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user == null) return UserModel.empty;

      final user = UserModel.fromFirebaseUser(cred.user!);
      await _firestoreService.saveUser(user.uid, user.toJson());

      AppLogger.info('AuthRepository: registered — ${user.email}');
      return user;
    } catch (e, st) {
      AppLogger.error('AuthRepository: signUp error', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Вход через email + пароль.
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user == null) return UserModel.empty;

      final user = UserModel.fromFirebaseUser(cred.user!);
      await _firestoreService.saveUser(user.uid, user.toJson());

      AppLogger.info('AuthRepository: signed in — ${user.email}');
      return user;
    } catch (e, st) {
      AppLogger.error('AuthRepository: signIn error', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Google ────────────────────────────────────────────────────

  Future<UserModel> signInWithGoogle() async {
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential?.user == null) return UserModel.empty;

      final user = UserModel.fromFirebaseUser(credential!.user!);
      await _firestoreService.saveUser(user.uid, user.toJson());

      AppLogger.info('AuthRepository: google sign-in — ${user.email}');
      return user;
    } catch (e, st) {
      AppLogger.error('AuthRepository: google error', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Reset Password ────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  // ── Sign Out ──────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      AppLogger.info('AuthRepository: signed out');
    } catch (e, st) {
      AppLogger.error('AuthRepository: signOut error', error: e, stackTrace: st);
      rethrow;
    }
  }
}
