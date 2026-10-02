import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/utils/validators.dart';
import 'package:bookhaven/features/auth/presentation/providers/forgot_password_controller.dart';
import 'package:bookhaven/shared/widgets/password_strength_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _codeKey = GlobalKey<FormState>();
  final _passKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  ForgotPasswordController get _notifier =>
      ref.read(forgotPasswordControllerProvider.notifier);

  // ---------- Actions ----------
  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (!_emailKey.currentState!.validate()) return;
    await _notifier.sendCode(_emailCtrl.text);
  }

  Future<void> _resend() async {
    final email = ref.read(forgotPasswordControllerProvider).email;
    final ok = await _notifier.sendCode(email);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code is on its way.')),
      );
    }
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!_codeKey.currentState!.validate()) return;
    await _notifier.verifyCode(_codeCtrl.text);
  }

  Future<void> _updatePassword() async {
    FocusScope.of(context).unfocus();
    if (!_passKey.currentState!.validate()) return;
    final ok = await _notifier.updatePassword(_passCtrl.text);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated. Please sign in.')),
    );
    context.go(AppRoutes.login);
  }

  Future<void> _handleBack() async {
    final step = ref.read(forgotPasswordControllerProvider).step;
    switch (step) {
      case ResetStep.email:
        context.canPop() ? context.pop() : context.go(AppRoutes.login);
        break;
      case ResetStep.code:
        _codeCtrl.clear();
        _notifier.backToEmail();
        break;
      case ResetStep.newPassword:
        await _notifier.cancel();
        if (mounted) context.go(AppRoutes.login);
        break;
    }
  }

  // ---------- Header copy ----------
  ({String label, String title, String subtitle}) _copy(
    ResetStep step,
    String email,
  ) {
    switch (step) {
      case ResetStep.email:
        return (
          label: 'ACCOUNT RECOVERY',
          title: 'Forgot your password?',
          subtitle: 'Enter the email linked to your account and we will send you a verification code.',
        );
      case ResetStep.code:
        return (
          label: 'VERIFY',
          title: 'Check your inbox.',
          subtitle: 'We sent a code to $email. Enter it below to continue.',
        );
      case ResetStep.newPassword:
        return (
          label: 'ALMOST DONE',
          title: 'Create a new password.',
          subtitle: 'Choose a strong password you have not used before.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final text = Theme.of(context).textTheme;
    final topPad = MediaQuery.of(context).padding.top;
    final copy = _copy(state.step, state.email);
    final stepIndex = state.step.index;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              // ---------- Header ----------
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  AppDimens.pagePadding,
                  topPad + 4,
                  AppDimens.pagePadding,
                  32,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.lightPrimary, Color(0xFF142B26)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      onPressed: _handleBack,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),
                    Row(
                      children: [
                        Text(
                          copy.label,
                          style: text.labelMedium?.copyWith(
                            color: AppColors.lightAccent,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        ...List.generate(3, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(left: 6),
                            width: i == stepIndex ? 22 : 8,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= stepIndex
                                  ? AppColors.lightAccent
                                  : AppColors.onPrimary.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: AppDimens.sm),
                    Text(
                      copy.title,
                      style: text.headlineLarge?.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.sm),
                    Container(
                      width: 48,
                      height: 1.5,
                      color: AppColors.lightAccent,
                    ),
                    const SizedBox(height: AppDimens.md),
                    Text(
                      copy.subtitle,
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- Step body ----------
              Padding(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(state.step),
                    child: switch (state.step) {
                      ResetStep.email => _buildEmailStep(state),
                      ResetStep.code => _buildCodeStep(state),
                      ResetStep.newPassword => _buildPasswordStep(state),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Step 1 ----------
  Widget _buildEmailStep(ForgotPasswordState state) {
    return Form(
      key: _emailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimens.sm),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendCode(),
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: Validators.email,
          ),
          _ErrorBanner(message: state.errorMessage),
          const SizedBox(height: AppDimens.xl),
          _SubmitButton(
            label: 'Send code',
            isLoading: state.isLoading,
            onPressed: _sendCode,
          ),
          const SizedBox(height: AppDimens.lg),
          Center(
            child: TextButton(
              onPressed: state.isLoading ? null : _handleBack,
              child: const Text('Back to Sign in'),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Step 2 ----------
  Widget _buildCodeStep(ForgotPasswordState state) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _codeKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimens.sm),
          TextFormField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onFieldSubmitted: (_) => _verify(),
            style: text.headlineSmall?.copyWith(letterSpacing: 8),
            decoration: const InputDecoration(
              labelText: 'Verification code',
              counterText: '',
            ),
            validator: Validators.otpCode,
          ),
          _ErrorBanner(message: state.errorMessage),
          const SizedBox(height: AppDimens.xl),
          _SubmitButton(
            label: 'Verify code',
            isLoading: state.isLoading,
            onPressed: _verify,
          ),
          const SizedBox(height: AppDimens.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Didn't get it?", style: text.bodyMedium),
              TextButton(
                onPressed: (state.resendIn > 0 || state.isLoading)
                    ? null
                    : _resend,
                child: Text(
                  state.resendIn > 0
                      ? 'Resend in ${state.resendIn}s'
                      : 'Resend code',
                ),
              ),
            ],
          ),
          Center(
            child: TextButton(
              onPressed: state.isLoading ? null : _handleBack,
              child: const Text('Use a different email'),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Step 3 ----------
  Widget _buildPasswordStep(ForgotPasswordState state) {
    return Form(
      key: _passKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimens.sm),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: Validators.newPassword,
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _passCtrl,
            builder: (_, value, __) =>
                PasswordStrengthMeter(password: value.text),
          ),
          const SizedBox(height: AppDimens.lg),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _updatePassword(),
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: Validators.confirmPassword(() => _passCtrl.text),
          ),
          _ErrorBanner(message: state.errorMessage),
          const SizedBox(height: AppDimens.xl),
          _SubmitButton(
            label: 'Update password',
            isLoading: state.isLoading,
            onPressed: _updatePassword,
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.buttonHeight,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Text(label),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.md),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: scheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusInput),
          border: Border.all(color: scheme.error.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 20, color: scheme.error),
            const SizedBox(width: AppDimens.sm),
            Expanded(
              child: Text(
                message!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.error),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().shakeX(hz: 3, amount: 4),
    );
  }
}
