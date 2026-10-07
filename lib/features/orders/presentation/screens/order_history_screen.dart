import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/orders/data/order_filter.dart';
import 'package:bookhaven/features/orders/presentation/providers/order_history_controller.dart';
import 'package:bookhaven/features/orders/presentation/widgets/order_history_card.dart';
import 'package:bookhaven/features/orders/presentation/widgets/order_history_skeleton.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      ref.read(orderHistoryControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final state = ref.watch(orderHistoryControllerProvider);
    final controller = ref.read(orderHistoryControllerProvider.notifier);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          const _Header(),
          _FilterBar(
            selected: state.filter,
            onSelected: (f) {
              if (_scroll.hasClients) _scroll.jumpTo(0);
              controller.setFilter(f);
            },
          ),
          Expanded(child: _buildBody(context, state, controller)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrderHistoryState state,
    OrderHistoryController controller,
  ) {
    if (state.isLoading) return const OrderHistorySkeleton();

    if (state.error != null && state.orders.isEmpty) {
      return _ErrorView(message: state.error!, onRetry: controller.refresh);
    }

    if (state.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: _EmptyView(filter: state.filter),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadding,
          AppDimens.sm,
          AppDimens.pagePadding,
          AppDimens.xxl,
        ),
        itemCount: state.orders.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.lg),
        itemBuilder: (context, i) {
          if (i == state.orders.length) {
            return _Footer(
              state: state,
              onRetry: () => controller.loadMore(retry: true),
            );
          }
          final order = state.orders[i];
          return OrderHistoryCard(
                key: ValueKey(order.id),
                order: order,
                onTap: () {
                  // Order Details / Delivery Tracking is the next page.
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Order details are coming next.'),
                      ),
                    );
                },
              )
              .animate()
              .fadeIn(duration: 320.ms, delay: (45 * math.min(i, 8)).ms)
              .slideY(
                begin: 0.06,
                end: 0,
                duration: 320.ms,
                curve: Curves.easeOut,
              );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dark = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.28),
      AppColors.lightPrimary,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lightPrimary, dark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.sm,
            AppDimens.xs,
            AppDimens.pagePadding,
            AppDimens.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.profile),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.onPrimary,
              ),
              Padding(
                padding: const EdgeInsets.only(left: AppDimens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR PURCHASES',
                      style: t.labelMedium?.copyWith(
                        color: AppColors.darkAccent,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'My orders',
                      style: t.headlineMedium?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimens.sm),
                    Container(
                      width: 44,
                      height: 2,
                      color: AppColors.darkAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final OrderFilter selected;
  final ValueChanged<OrderFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.pagePadding,
          vertical: AppDimens.md,
        ),
        itemCount: OrderFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimens.sm),
        itemBuilder: (_, i) {
          final f = OrderFilter.values[i];
          final isSel = f == selected;
          return GestureDetector(
            onTap: () => onSelected(f),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? c.primary : c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSel ? c.primary : c.border),
              ),
              child: Text(
                f.label,
                style: t.labelLarge?.copyWith(
                  color: isSel ? AppColors.onPrimary : c.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final OrderHistoryState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimens.lg),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    if (state.loadMoreError != null) {
      return Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Could not load more. Tap to retry'),
        ),
      );
    }

    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
        child: Column(
          children: [
            Container(width: 44, height: 1, color: c.accent),
            const SizedBox(height: AppDimens.sm),
            Text(
              'THAT\'S EVERY ORDER',
              style: t.labelMedium?.copyWith(
                color: c.textSecondary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: AppDimens.lg);
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.filter});

  final OrderFilter filter;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final isAll = filter == OrderFilter.all;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimens.xxl),
      children: [
        const SizedBox(height: AppDimens.xxl),
        Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surface,
              border: Border.all(color: c.border),
            ),
            child: Icon(Icons.receipt_long_outlined, size: 40, color: c.accent),
          ),
        ),
        const SizedBox(height: AppDimens.xl),
        Text(
          isAll ? 'No orders yet' : 'No ${filter.label.toLowerCase()} orders',
          textAlign: TextAlign.center,
          style: t.headlineSmall?.copyWith(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        Text(
          isAll
              ? 'Once you place an order, it will be waiting here for you.'
              : 'Nothing matches this filter right now.',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: c.textSecondary),
        ),
        if (isAll) ...[
          const SizedBox(height: AppDimens.xl),
          Center(
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.categories),
              child: const Text('Browse books'),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: c.error),
            const SizedBox(height: AppDimens.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppDimens.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
