import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/admin/data/admin_order.dart';
import 'package:bookhaven/features/admin/presentation/providers/admin_orders_controller.dart';
import 'package:bookhaven/features/admin/presentation/widgets/admin_order_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class ManageOrdersScreen extends ConsumerStatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  ConsumerState<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends ConsumerState<ManageOrdersScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 300) {
      ref.read(adminOrdersControllerProvider.notifier).loadMore();
    }
  }

  void _openOrder(AdminOrder order) {
    // Replaced by context.push(AppRoutes.adminOrderDetailPath(order.id))
    // when we build Admin Order Detail / Status Update.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${order.orderNumber}: next page we build')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final state = ref.watch(adminOrdersControllerProvider);
    final controller = ref.read(adminOrdersControllerProvider.notifier);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppDimens.sm,
              MediaQuery.paddingOf(context).top + AppDimens.sm,
              AppDimens.pagePadding,
              AppDimens.xl,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.primary, Color.lerp(c.primary, Colors.black, 0.28)!],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.onPrimary,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ADMIN',
                            style: text.labelMedium?.copyWith(
                              color: AppColors.onPrimary.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            'Manage orders',
                            style: text.headlineSmall?.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                Padding(
                  padding: const EdgeInsets.only(left: AppDimens.md),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _search,
                    builder: (context, value, _) {
                      return TextField(
                        controller: _search,
                        onChanged: controller.setQuery,
                        textInputAction: TextInputAction.search,
                        cursorColor: AppColors.onPrimary,
                        style: const TextStyle(color: AppColors.onPrimary),
                        decoration: InputDecoration(
                          hintText: 'Order number, customer or email',
                          hintStyle: TextStyle(
                            color: AppColors.onPrimary.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.onPrimary.withValues(alpha: 0.8),
                          ),
                          suffixIcon: value.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.onPrimary,
                                  ),
                                  onPressed: () {
                                    _search.clear();
                                    controller.setQuery('');
                                  },
                                ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusInput,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusInput,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusInput,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.onPrimary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Status filter chips
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.pagePadding,
                vertical: AppDimens.md,
              ),
              itemCount: AdminOrderFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppDimens.sm),
              itemBuilder: (context, i) {
                final f = AdminOrderFilter.values[i];
                final selected = f == state.filter;
                return ChoiceChip(
                  showCheckmark: false,
                  selected: selected,
                  label: Text('${f.label} · ${state.countFor(f)}'),
                  labelStyle: text.labelLarge?.copyWith(
                    color: selected ? AppColors.onPrimary : c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: c.primary,
                  backgroundColor: c.surface,
                  side: BorderSide(color: selected ? c.primary : c.border),
                  onSelected: (_) => controller.setFilter(f),
                );
              },
            ),
          ),

          // List
          Expanded(child: _buildBody(context, state, controller)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminOrdersState state,
    AdminOrdersController controller,
  ) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    if (state.isLoading && state.items.isEmpty) {
      return const _OrdersSkeleton();
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: c.error),
              const SizedBox(height: AppDimens.md),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppDimens.lg),
              FilledButton(
                onPressed: controller.refresh,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.inbox_outlined, size: 44, color: c.textSecondary),
            const SizedBox(height: AppDimens.md),
            Text(
              state.query.isEmpty
                  ? 'No orders here yet'
                  : 'No orders match your search',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadding,
              AppDimens.xs,
              AppDimens.pagePadding,
              AppDimens.xxl,
            ),
            itemCount: state.items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimens.md),
            itemBuilder: (context, i) {
              if (i == state.items.length) {
                if (state.isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppDimens.lg),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
                  child: Text(
                    state.hasMore
                        ? ''
                        : "THAT'S EVERY ORDER  ·  ${state.total}",
                    textAlign: TextAlign.center,
                    style: text.labelMedium?.copyWith(color: c.textSecondary),
                  ),
                );
              }
              final order = state.items[i];
              return AdminOrderTile(
                order: order,
                onTap: () =>
                    context.push(AppRoutes.adminOrderDetailPath(order.id)),
              );
            },
          ),
        ),
        if (state.isLoading)
          LinearProgressIndicator(
            minHeight: 2,
            color: c.accent,
            backgroundColor: Colors.transparent,
          ),
      ],
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Shimmer.fromColors(
      baseColor: c.border,
      highlightColor: c.surface,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.pagePadding),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.md),
        itemBuilder: (_, __) => Container(
          height: 98,
          decoration: BoxDecoration(
            color: c.border,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          ),
        ),
      ),
    );
  }
}
