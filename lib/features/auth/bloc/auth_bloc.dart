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

/// Fired after a Google new-user completes subject selection
class AuthGoogleSubjectsSelected extends AuthEvent {
  final UserModel user;
  final List<String> subjectIds;
  final String appLanguage;
  AuthGoogleSubjectsSelected({
    required this.user,
    required this.subjectIds,
    required this.appLanguage,
  });
  @override
  List<Object?> get props => [user, subjectIds, appLanguage];
}

// Fired from the profile screen when the user edits their subject selection.
class AuthSubjectsUpdateRequested extends AuthEvent {
  final String uid;
  final List<String> subjectIds;
  AuthSubjectsUpdateRequested({required this.uid, required this.subjectIds});
  @override
  List<Object?> get props => [uid, subjectIds];
}

class AuthSignOutRequested extends AuthEvent {}

class AuthDeleteAccountRequested extends AuthEvent {}

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

/// New Google user needs to pick subjects before entering the app
class AuthNeedsSubjectSelection extends AuthState {
  final UserModel user;
  AuthNeedsSubjectSelection(this.user);
  @override
  List<Object?> get props => [user];
}

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
    on<AuthGoogleSubjectsSelected>(_onGoogleSubjectsSelected);
    on<AuthSubjectsUpdateRequested>(_onSubjectsUpdate);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthDeleteAccountRequested>(_onDeleteAccount);
    on<AuthUserRefreshed>(_onRefresh);
  }

  Future<void> _onRefresh(AuthUserRefreshed event, Emitter<AuthState> emit) async {
    try {
      final user = await _repository.fetchCurrentUser();
      if (user != null) emit(AuthAuthenticated(user));
    } catch (_) {}
  }

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.fetchCurrentUser();
      if (user != null) {
        // Even persisted users who somehow have empty subjects go through selection
        if (user.selectedSubjectIds.isEmpty) {
          emit(AuthNeedsSubjectSelection(user));
        } else {
          emit(AuthAuthenticated(user));
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      if (user.selectedSubjectIds.isEmpty) {
        emit(AuthNeedsSubjectSelection(user));
      } else {
        emit(AuthAuthenticated(user));
      }
    } on Exception catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.signUpWithEmail(
        email: event.email,
        password: event.password,
        subjectIds: event.subjectIds,
      );
      emit(AuthAuthenticated(user));
    } on Exception catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onGoogle(AuthGoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _repository.signInWithGoogle();
      if (result.isNewUser || result.user.selectedSubjectIds.isEmpty) {
        // New Google user → needs subject selection
        emit(AuthNeedsSubjectSelection(result.user));
      } else {
        emit(AuthAuthenticated(result.user));
      }
    } on Exception catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSubjectsUpdate(
      AuthSubjectsUpdateRequested event, Emitter<AuthState> emit) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    emit(AuthLoading());
    try {
      await _repository.updateSelectedSubjects(event.uid, event.subjectIds);
      // Rebuild user with updated subject list — no extra round-trip needed.
      final updatedUser = current.user.copyWith(
        selectedSubjectIds: event.subjectIds,
      );
      emit(AuthAuthenticated(updatedUser));
    } on Exception catch (e) {
      emit(AuthAuthenticated(current.user)); // revert on error
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onGoogleSubjectsSelected(
      AuthGoogleSubjectsSelected event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final updatedUser = await _repository.saveSubjectsAndLanguage(
        uid: event.user.uid,
        subjectIds: event.subjectIds,
        appLanguage: event.appLanguage,
      );
      emit(AuthAuthenticated(updatedUser));
    } on Exception catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _repository.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onDeleteAccount(
      AuthDeleteAccountRequested event, Emitter<AuthState> emit) async {
    final current = state;
    emit(AuthLoading());
    try {
      await _repository.deleteAccount();
      emit(AuthUnauthenticated());
    } catch (e) {
      // Firebase throws requires-recent-login if the session is too old.
      // Revert to authenticated so the user can sign out/in and retry.
      if (current is AuthAuthenticated) emit(current);
      emit(AuthError(e.toString()));
    }
  }
}
