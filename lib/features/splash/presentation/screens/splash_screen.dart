import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _minDisplay = Duration(milliseconds: 30000);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final results = await Future.wait<AuthStatus?>([
      ref.read(authRepositoryProvider).resolveStatus(),
      Future<AuthStatus?>.delayed(_minDisplay, () => null),
    ]);

    if (!mounted) return;

    final status = results.first ?? AuthStatus.signedOut;
    switch (status) {
      case AuthStatus.admin || AuthStatus.user:
        context.go(AppRoutes.home);
      case AuthStatus.signedOut:
        context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = AppColors.darkAccent;
    const parchment = AppColors.lightBackground;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.darkBackground,
      ),
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.lightPrimary, AppColors.darkBackground],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child:
                        CustomPaint(
                              size: const Size(26, 120),
                              painter: _RibbonPainter(gold),
                            )
                            .animate()
                            .slideY(
                              begin: -1,
                              end: 0,
                              duration: 900.ms,
                              curve: Curves.easeOutCubic,
                            )
                            .fadeIn(duration: 500.ms),
                  ),
                ),
                Positioned.fill(
                  child: SafeArea(
                    child: Column(
                      children: [
                        const Spacer(flex: 5),

                        Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: gold, width: 1.2),
                              ),
                              child: const Icon(
                                Icons.auto_stories_outlined,
                                size: 46,
                                color: gold,
                              ),
                            )
                            .animate(delay: 500.ms)
                            .fadeIn(duration: 700.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                              duration: 800.ms,
                              curve: Curves.easeOutBack,
                            ),

                        const SizedBox(height: 32),

                        Text(
                              'Book Haven',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 48,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: parchment,
                              ),
                            )
                            .animate(delay: 900.ms)
                            .fadeIn(duration: 700.ms)
                            .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                        const SizedBox(height: 14),

                        Container(width: 72, height: 1, color: gold)
                            .animate(delay: 1300.ms)
                            .scaleX(
                              begin: 0,
                              end: 1,
                              duration: 600.ms,
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.center,
                            ),

                        const SizedBox(height: 14),

                        Text(
                          'A HAVEN FOR EVERY READER',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 3.2,
                            color: parchment.withAlpha(178),
                          ),
                        ).animate(delay: 1500.ms).fadeIn(duration: 700.ms),

                        const Spacer(flex: 4),

                        SizedBox(
                          width: 56,
                          child: LinearProgressIndicator(
                            minHeight: 1.5,
                            color: gold,
                            backgroundColor: gold.withAlpha(51),
                          ),
                        ).animate(delay: 1700.ms).fadeIn(duration: 500.ms),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - 16)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black.withAlpha(90), 4, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) => old.color != color;
}
