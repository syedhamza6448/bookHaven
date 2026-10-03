import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bookhaven/features/auth/presentation/screens/login_screen.dart';
import 'package:bookhaven/features/auth/presentation/screens/register_screen.dart';
import 'package:bookhaven/features/catalog/presentation/providers/book_list_controller.dart';
import 'package:bookhaven/features/catalog/presentation/screens/book_details_screen.dart';
import 'package:bookhaven/features/catalog/presentation/screens/book_list_screen.dart';
import 'package:bookhaven/features/home/presentation/screens/home_screen.dart';
import 'package:bookhaven/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookList,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BookListScreen(
            args: BookListArgs.fromQuery(state.uri.queryParameters),
          ),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.bookDetails,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 400),
          child: BookDetailsScreen(
            bookId: state.pathParameters['id']!,
            heroTag: state.uri.queryParameters['hero'],
          ),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              ),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        pageBuilder: (context, state) =>
            _fadePage(state, const _PlaceholderScreen('Admin Dashboard')),
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 600),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
