import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nerpa_academy/data/models/models.dart';
import 'package:nerpa_academy/data/repositories/auth_repository.dart';


// ─── Events ──────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final List<String> subjectIds;
  AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.subjectIds,
  });
  @override
  List<Object?> get props => [email, password, subjectIds];
}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthUserRefreshed extends AuthEvent {}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthGoogleSignInRequested>(_onGoogle);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthUserRefreshed>(_onRefresh);
  }

  Future<void> _onRefresh(
      AuthUserRefreshed event, Emitter<AuthState> emit) async {
    try {
      final user = await _repository.fetchCurrentUser();
      if (user != null) emit(AuthAuthenticated(user));
    } catch (_) {}
  }

  Future<void> _onCheck(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.fetchCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } on Exception catch (e) {
      emit(AuthError(_mapFirebaseError(e.toString())));
    }
  }

  Future<void> _onSignUp(
      AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.signUpWithEmail(
        email: event.email,
        password: event.password,
        subjectIds: event.subjectIds,
      );
      emit(AuthAuthenticated(user));
    } on Exception catch (e) {
      emit(AuthError(_mapFirebaseError(e.toString())));
    }
  }

  Future<void> _onGoogle(
      AuthGoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } on Exception catch (e) {
      emit(AuthError(_mapFirebaseError(e.toString())));
    }
  }

  Future<void> _onSignOut(
      AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _repository.signOut();
    emit(AuthUnauthenticated());
  }

  String _mapFirebaseError(String error) {
    if (error.contains('user-not-found') ||
        error.contains('wrong-password')) {
      return 'Неверный email или пароль';
    }
    if (error.contains('email-already-in-use')) {
      return 'Этот email уже используется';
    }
    if (error.contains('network-request-failed')) {
      return 'Нет подключения к интернету';
    }
    return 'Что-то пошло не так';
  }
}
