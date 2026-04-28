import 'package:currency_converter/services/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService) : super(const AuthState()) {
    on<LoginWithEmail>(_onLoginWithEmail);
    on<SignUpWithEmail>(_onSignUpWithEmail);
    on<LoginWithGoogle>(_onLoginWithGoogle);
    on<ForgotPassword>(_onForgotPassword);
  }

  // Email Login
  Future<void> _onLoginWithEmail(
    LoginWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      await authService.signInWithEmail(event.email, event.password);

      emit(state.copyWith(status: AuthStatus.success));
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _friendlyError(e.code),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  // Email Signup
  Future<void> _onSignUpWithEmail(
    SignUpWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    if (event.email.isEmpty || event.password.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: "Please fill in all fields.",
        ),
      );
      return;
    }
    if (event.password.length < 6) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: "Password must be at least 6 characters.",
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      await authService.signUpWithEmail(event.email, event.password);

      emit(state.copyWith(status: AuthStatus.success));
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _friendlyError(e.code),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  // Google Login
  Future<void> _onLoginWithGoogle(
    LoginWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.googleLoading, errorMessage: null));

    try {
      final result = await authService.signInWithGoogle();

      if (result == null) {
        emit(state.copyWith(status: AuthStatus.initial));
        return;
      }

      emit(state.copyWith(status: AuthStatus.success));
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Google sign-in failed. Please try again.',
        ),
      );
    }
  }

  // Forgot Password
  Future<void> _onForgotPassword(
    ForgotPassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authService.resetPassword(event.email);

      emit(state.copyWith(status: AuthStatus.passwordResetSent));
    } on FirebaseAuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: e.code == 'user-not-found'
              ? 'No account found with this email.'
              : 'Failed to send reset email. Try again.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  // Friendly error messages
  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
