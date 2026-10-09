import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/router/main_shell.dart';
import 'package:bookhaven/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:bookhaven/features/admin/presentation/screens/book_form_screen.dart';
import 'package:bookhaven/features/admin/presentation/screens/manage_books_screen.dart';
import 'package:bookhaven/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bookhaven/features/auth/presentation/screens/login_screen.dart';
import 'package:bookhaven/features/auth/presentation/screens/register_screen.dart';
import 'package:bookhaven/features/cart/presentation/screens/cart_screen.dart';
import 'package:bookhaven/features/catalog/presentation/providers/book_list_controller.dart';
import 'package:bookhaven/features/catalog/presentation/screens/book_details_screen.dart';
import 'package:bookhaven/features/catalog/presentation/screens/book_list_screen.dart';
import 'package:bookhaven/features/catalog/presentation/screens/categories_screen.dart';
import 'package:bookhaven/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:bookhaven/features/home/presentation/screens/home_screen.dart';
import 'package:bookhaven/features/orders/presentation/screens/order_details_screen.dart';
import 'package:bookhaven/features/orders/presentation/screens/order_history_screen.dart';
import 'package:bookhaven/features/orders/presentation/screens/order_success_screen.dart';
import 'package:bookhaven/features/profile/presentation/screens/addresses_screen.dart';
import 'package:bookhaven/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:bookhaven/features/profile/presentation/screens/payment_methods_screen.dart';
import 'package:bookhaven/features/profile/presentation/screens/profile_screen.dart';
import 'package:bookhaven/features/reviews/presentation/screens/write_review_screen.dart';
import 'package:bookhaven/features/search/presentation/screens/search_screen.dart';
import 'package:bookhaven/features/splash/presentation/screens/splash_screen.dart';
import 'package:bookhaven/features/wishlist/presentation/screens/wishlist_screen.dart';
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
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main tabs with the bottom navigation bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.categories,
                builder: (context, state) => CategoriesScreen(
                  initialTab: state.uri.queryParameters['tab'] == 'authors'
                      ? 1
                      : 0,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wishlist,
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen pages (cover the bottom navigation bar)
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
        path: AppRoutes.search,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: SearchScreen(
            initialQuery: state.uri.queryParameters['q'],
            initialGenreId: state.uri.queryParameters['genre'],
          ),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CheckoutScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: OrderSuccessScreen(
            orderId: state.pathParameters['id']!,
            orderNumber: state.uri.queryParameters['n'],
          ),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AddressesScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentMethods,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PaymentMethodsScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.orders,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const OrderHistoryScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.orderDetails,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: OrderDetailsScreen(orderId: state.pathParameters['id']!),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.writeReview,
        pageBuilder: (context, state) {
          final q = state.uri.queryParameters;
          return CustomTransitionPage(
            key: state.pageKey,
            child: WriteReviewScreen(
              bookId: state.pathParameters['bookId']!,
              title: q['title'] ?? '',
              authorName: q['author'] ?? '',
              coverUrl: q['cover'],
            ),
            transitionsBuilder: (context, animation, secondary, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminBooks,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ManageBooksScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminBookAdd,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BookFormScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminBookEdit,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BookFormScreen(bookId: state.pathParameters['id']!),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
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
