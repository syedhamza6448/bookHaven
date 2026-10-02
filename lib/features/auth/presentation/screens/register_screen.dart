import 'package:bookhaven/shared/widgets/password_strength_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../providers/register_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _termsError = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    setState(() => _termsError = !_acceptedTerms);
    if (!valid || !_acceptedTerms) return;

    final result = await ref
        .read(registerControllerProvider.notifier)
        .register(
          fullName: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
    if (!mounted) return;

    switch (result) {
      case RegisterResult.signedIn:
        context.go(AppRoutes.home);
        break;
      case RegisterResult.confirmEmail:
        await _showConfirmDialog();
        if (mounted) context.go(AppRoutes.login);
        break;
      case RegisterResult.failed:
        break;
    }
  }

  Future<void> _showConfirmDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.mark_email_read_outlined,
          size: 36,
          color: Theme.of(ctx).colorScheme.primary,
        ),
        title: const Text('Check your inbox'),
        content: Text(
          'We sent a confirmation link to ${_emailCtrl.text.trim()}. '
          'Verify your email, then sign in to start reading.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Go to Sign in'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final state = ref.watch(registerControllerProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
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
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.login),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(
                    'NEW READER',
                    style: text.labelMedium?.copyWith(
                      color: AppColors.lightAccent,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    'Join the haven.',
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
                    'Create an account to save favourites, review books and track your orders.',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            // ---------- Form ----------
            Padding(
              padding: const EdgeInsets.all(AppDimens.pagePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children:
                      [
                            const SizedBox(height: AppDimens.sm),
                            TextFormField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: Validators.fullName,
                            ),
                            const SizedBox(height: AppDimens.lg),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: Validators.email,
                            ),
                            const SizedBox(height: AppDimens.lg),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
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
                              valueListenable: _passwordCtrl,
                              builder: (_, value, __) =>
                                  PasswordStrengthMeter(password: value.text),
                            ),
                            const SizedBox(height: AppDimens.lg),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: const Icon(
                                  Icons.lock_reset_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: Validators.confirmPassword(
                                () => _passwordCtrl.text,
                              ),
                            ),
                            const SizedBox(height: AppDimens.lg),

                            // Terms
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setState(() {
                                _acceptedTerms = !_acceptedTerms;
                                if (_acceptedTerms) _termsError = false;
                              }),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _acceptedTerms,
                                    onChanged: (v) => setState(() {
                                      _acceptedTerms = v ?? false;
                                      if (_acceptedTerms) _termsError = false;
                                    }),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        'I agree to the Terms of Service and Privacy Policy.',
                                        style: text.bodySmall?.copyWith(
                                          color: _termsError
                                              ? scheme.error
                                              : scheme.onSurface.withOpacity(
                                                  0.75,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Server error
                            if (state.errorMessage != null) ...[
                              const SizedBox(height: AppDimens.md),
                              Container(
                                padding: const EdgeInsets.all(AppDimens.md),
                                decoration: BoxDecoration(
                                  color: scheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusInput,
                                  ),
                                  border: Border.all(
                                    color: scheme.error.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      size: 20,
                                      color: scheme.error,
                                    ),
                                    const SizedBox(width: AppDimens.sm),
                                    Expanded(
                                      child: Text(
                                        state.errorMessage!,
                                        style: text.bodySmall?.copyWith(
                                          color: scheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn().shakeX(hz: 3, amount: 4),
                            ],

                            const SizedBox(height: AppDimens.xl),
                            SizedBox(
                              height: AppDimens.buttonHeight,
                              child: FilledButton(
                                onPressed: state.isLoading ? null : _submit,
                                child: state.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : const Text('Create account'),
                              ),
                            ),
                            const SizedBox(height: AppDimens.lg),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: text.bodyMedium,
                                ),
                                TextButton(
                                  onPressed: state.isLoading
                                      ? null
                                      : () => context.go(AppRoutes.login),
                                  child: const Text('Sign in'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.lg),
                          ]
                          .animate(interval: 60.ms)
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.06, end: 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
