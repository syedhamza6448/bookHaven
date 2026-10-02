import 'package:bookhaven/core/errors/auth_error_mapper.dart';
import 'package:bookhaven/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RegisterResult { signedIn, confirmEmail, failed }

class RegisterState {
  const RegisterState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;
}

class RegisterController extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  Future<RegisterResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const RegisterState(isLoading: true);
    try {
      final res = await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            fullName: fullName.trim(),
            email: email.trim(),
            password: password,
          );

      final user = res.user;
      if (user == null) {
        state = const RegisterState(
          errorMessage: 'Could not create your account. Please try again.',
        );
        return RegisterResult.failed;
      }

      if (user.identities?.isEmpty ?? false) {
        state = const RegisterState(
          errorMessage:
              'An account with this email already exists. Try signing in.',
        );
        return RegisterResult.failed;
      }

      state = const RegisterState();
      return res.session != null
          ? RegisterResult.signedIn
          : RegisterResult.confirmEmail;
    } catch (e) {
      state = RegisterState(errorMessage: authErrorMessage(e));
      return RegisterResult.failed;
    }
  }

  void clearError() => state = const RegisterState();
}

final registerControllerProvider =
    NotifierProvider.autoDispose<RegisterController, RegisterState>(
      RegisterController.new,
    );
