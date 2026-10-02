import 'package:bookhaven/core/errors/auth_error_mapper.dart';
import 'package:bookhaven/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginState {
  final bool isLoading;
  final bool isGoogleLoading;
  final String? error;

  const LoginState({
    this.isLoading = false,
    this.isGoogleLoading = false,
    this.error,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? isGoogleLoading,
    String? error,
    bool clearError = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: authErrorMessage(e));
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isGoogleLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = state.copyWith(isGoogleLoading: false);
    } catch (e) {
      state = state.copyWith(
        isGoogleLoading: false,
        error: authErrorMessage(e),
      );
    }
  }
}

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
      LoginController.new,
    );
