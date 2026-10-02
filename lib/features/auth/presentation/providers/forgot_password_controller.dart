import 'dart:async';

import 'package:bookhaven/core/errors/auth_error_mapper.dart';
import 'package:bookhaven/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ResetStep { email, code, newPassword }

class ForgotPasswordState {
  const ForgotPasswordState({
    this.step = ResetStep.email,
    this.email = '',
    this.isLoading = false,
    this.errorMessage,
    this.resendIn = 0,
  });

  final ResetStep step;
  final String email;
  final bool isLoading;
  final String? errorMessage;
  final int resendIn;

  ForgotPasswordState copyWith({
    ResetStep? step,
    String? email,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    int? resendIn,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      resendIn: resendIn ?? this.resendIn,
    );
  }
}

class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  Timer? _timer;

  @override
  ForgotPasswordState build() {
    ref.onDispose(() => _timer?.cancel());
    return const ForgotPasswordState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  void _startCooldown() {
    _timer?.cancel();
    state = state.copyWith(resendIn: 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.resendIn - 1;
      if (left <= 0) {
        t.cancel();
        state = state.copyWith(resendIn: 0);
      } else {
        state = state.copyWith(resendIn: left);
      }
    });
  }

  /// Step 1 (and resend): email the code.
  Future<bool> sendCode(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.sendPasswordResetCode(email);
      state = state.copyWith(
        isLoading: false,
        step: ResetStep.code,
        email: email.trim(),
      );
      _startCooldown();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: authErrorMessage(e),
      );
      return false;
    }
  }

  /// Step 2: verify the code (this also signs the user in with a recovery session).
  Future<bool> verifyCode(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.verifyPasswordResetCode(
        email: state.email,
        code: code,
      );
      if (res.session == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'That code is invalid or has expired. Request a new one.',
        );
        return false;
      }
      state = state.copyWith(isLoading: false, step: ResetStep.newPassword);
      return true;
    } on AuthException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'That code is invalid or has expired. Request a new one.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: authErrorMessage(e),
      );
      return false;
    }
  }

  /// Step 3: set the new password, then sign out so the user logs in fresh.
  Future<bool> updatePassword(String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.updatePassword(password);
      await _repo.signOut();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final message =
          e is AuthException &&
              e.message.toLowerCase().contains('different from the old')
          ? 'Please choose a password you have not used before.'
          : authErrorMessage(e);
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    }
  }

  void backToEmail() {
    state = state.copyWith(step: ResetStep.email, clearError: true);
  }

  /// Leaving mid-reset after the code was verified: drop the recovery session.
  Future<void> cancel() async {
    if (state.step == ResetStep.newPassword) {
      try {
        await _repo.signOut();
      } catch (_) {}
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final forgotPasswordControllerProvider =
    NotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>(
      ForgotPasswordController.new,
    );
