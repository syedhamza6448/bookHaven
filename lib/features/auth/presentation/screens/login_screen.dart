import 'dart:async';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/utils/validators.dart';
import 'package:bookhaven/features/auth/data/auth_repository.dart';
import 'package:bookhaven/features/auth/presentation/providers/login_controller.dart';
import 'package:bookhaven/shared/widgets/app_primary_button.dart';
import 'package:bookhaven/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  StreamSubscription<AuthState>? _sub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Catches the return from Google sign-in (deep link).
    _sub = ref.read(authRepositoryProvider).authStateChanges.listen((s) {
      if (s.event == AuthChangeEvent.signedIn) _navigateAfterAuth();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterAuth() async {
    if (_navigated) return;
    _navigated = true;
    final status = await ref.read(authRepositoryProvider).resolveStatus();
    if (!mounted) return;
    switch (status) {
      case AuthStatus.admin:
        context.go(AppRoutes.adminDashboard);
      case AuthStatus.user:
        context.go(AppRoutes.home);
      case AuthStatus.signedOut:
        _navigated = false;
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(loginControllerProvider.notifier)
        .signIn(_emailCtrl.text, _passCtrl.text);
    if (ok) _navigateAfterAuth();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gold = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final state = ref.watch(loginControllerProvider);

    ref.listen(loginControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            _Header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.pagePadding,
                AppDimens.xl,
                AppDimens.pagePadding,
                AppDimens.xl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SIGN IN',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: gold, letterSpacing: 2.4)),
                    const SizedBox(height: AppDimens.sm),
                    Text(
                      'Welcome back.',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        height: 1.05,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),
                    Container(width: 48, height: 1.5, color: gold),
                    const SizedBox(height: AppDimens.md),
                    Text(
                      'Pick up where you left off in your next chapter.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.65)),
                    ),
                    const SizedBox(height: AppDimens.xl),
                    AppTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppDimens.lg),
                    AppTextField(
                      controller: _passCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                      onSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: AppDimens.sm),
                    AppPrimaryButton(
                      label: 'Sign In',
                      isLoading: state.isLoading,
                      onPressed: state.isGoogleLoading ? null : _submit,
                    ),
                    const SizedBox(height: AppDimens.xl),
                    Row(children: [
                      Expanded(child: Divider(color: theme.dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(letterSpacing: 2)),
                      ),
                      Expanded(child: Divider(color: theme.dividerColor)),
                    ]),
                    const SizedBox(height: AppDimens.xl),
                    SizedBox(
                      width: double.infinity,
                      height: AppDimens.buttonHeight,
                      child: OutlinedButton(
                        onPressed: (state.isLoading || state.isGoogleLoading)
                            ? null
                            : () => ref
                                .read(loginControllerProvider.notifier)
                                .signInWithGoogle(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.dividerColor),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusButton),
                          ),
                        ),
                        child: state.isGoogleLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('G',
                                      style: GoogleFonts.cormorantGaramond(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: gold)),
                                  const SizedBox(width: 12),
                                  Text('Continue with Google',
                                      style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.xl),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('New to Book Haven?',
                              style: theme.textTheme.bodyMedium),
                          TextButton(
                            onPressed: () => context.push(AppRoutes.register),
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                    ),
                  ]
                      .animate(interval: 60.ms)
                      .fadeIn(duration: 450.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: top + 36, bottom: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lightPrimary, Color(0xFF132B26)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkAccent,
            ),
            child: const Icon(Icons.auto_stories,
                color: AppColors.lightPrimary, size: 30),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 14),
          Text(
            'Book Haven',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.onPrimary,
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
        ],
      ),
    );
  }
}