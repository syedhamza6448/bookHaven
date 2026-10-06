import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/wishlist/data/wishlist_items_repository.dart';
import 'package:bookhaven/features/wishlist/presentation/providers/wishlist_controller.dart';
import 'package:bookhaven/features/wishlist/presentation/widgets/wishlist_shelf_row.dart';
import 'package:bookhaven/features/wishlist/presentation/widgets/wishlist_skeleton.dart';
import 'package:bookhaven/shared/models/book.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  String _message(Object e) {
    if (e is WishlistException) return e.message;
    return kDebugMode
        ? e.toString()
        : 'Something went wrong. Please try again.';
  }

  void _open(BuildContext context, Book book, String heroTag) {
    context.push(AppRoutes.bookDetailsPath(book.id, heroTag: heroTag));
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, Book book) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(wishlistControllerProvider.notifier);
    try {
      final index = await controller.remove(book);
      if (index == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Removed "${book.title}"'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.darkAccent,
              onPressed: () {
                controller.restore(book, index).catchError((_) {});
              },
            ),
          ),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_message(e))));
    }
  }

  Future<void> _moveToCart(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(wishlistControllerProvider.notifier).moveToCart(book);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Moved to your cart'),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () => router.go(AppRoutes.cart),
            ),
          ),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_message(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final async = ref.watch(wishlistControllerProvider);
    final count = async.value?.length;

    return Scaffold(
      backgroundColor: c.bg,
      body: RefreshIndicator(
        color: c.primary,
        onRefresh: () =>
            ref.read(wishlistControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(count: count)),
            ...async.when(
              skipLoadingOnReload: true,
              loading: () => [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppDimens.pagePadding,
                      AppDimens.xl,
                      AppDimens.pagePadding,
                      0,
                    ),
                    child: WishlistSkeleton(),
                  ),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorView(
                    message: _message(e),
                    onRetry: () => ref.invalidate(wishlistControllerProvider),
                  ),
                ),
              ],
              data: (books) {
                if (books.isEmpty) {
                  return [
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyView(),
                    ),
                  ];
                }
                final rowCount = (books.length / 2).ceil();
                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.pagePadding,
                      AppDimens.xl,
                      AppDimens.pagePadding,
                      AppDimens.xl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final pair = books.skip(i * 2).take(2).toList();
                        return WishlistShelfRow(
                              books: pair,
                              onOpen: (b, tag) => _open(context, b, tag),
                              onRemove: (b) => _remove(context, ref, b),
                              onMoveToCart: (b) => _moveToCart(context, ref, b),
                            )
                            .animate()
                            .fadeIn(
                              duration: 350.ms,
                              delay: (60 * i.clamp(0, 6)).ms,
                            )
                            .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
                      }, childCount: rowCount),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final theme = Theme.of(context);
    final top = MediaQuery.of(context).padding.top;

    final subtitle = count == null
        ? 'Loading your shelf…'
        : count == 0
        ? 'Nothing saved yet'
        : count == 1
        ? '1 book waiting for you'
        : '$count books waiting for you';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        top + AppDimens.xl,
        AppDimens.pagePadding,
        AppDimens.xxl,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, Color.lerp(c.primary, Colors.black, 0.4)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR READING LIST',
            style: theme.textTheme.labelMedium?.copyWith(color: c.accent),
          ),
          const SizedBox(height: 6),
          Text(
            'Wishlist',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Container(width: 44, height: 2, color: c.accent),
          const SizedBox(height: AppDimens.md),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppDimens.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.accent, width: 1.5),
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              size: 38,
              color: c.accent,
            ),
          ),
          const SizedBox(height: AppDimens.xl),
          Text(
            'Your shelf is empty',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            'Tap the bookmark on any book to keep it here for later.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppDimens.xl),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.categories),
            child: const Text('Browse books'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppDimens.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: c.textSecondary),
          const SizedBox(height: AppDimens.lg),
          Text(
            'Could not load your wishlist',
            style: theme.textTheme.titleLarge?.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppDimens.xl),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
