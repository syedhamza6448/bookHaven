import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/admin/data/admin_dashboard_repository.dart';
import 'package:bookhaven/features/admin/presentation/providers/admin_dashboard_providers.dart';
import 'package:bookhaven/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  void _soon(BuildContext context, String page) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$page is the next page we build.')),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final async = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: RefreshIndicator(
        color: c.primary,
        onRefresh: () async {
          ref.invalidate(adminDashboardProvider);
          await ref
              .read(adminDashboardProvider.future)
              .catchError((_) => _empty);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            async.when(
              loading: () => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: c.primary),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  message: e.toString().contains('Admins only')
                      ? 'This area is for administrators only.'
                      : 'Could not load the dashboard.',
                  onRetry: () => ref.invalidate(adminDashboardProvider),
                ),
              ),
              data: (s) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.pagePadding,
                  AppDimens.xl,
                  AppDimens.pagePadding,
                  AppDimens.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _StatsGrid(stats: s),
                    const SizedBox(height: AppDimens.xl),
                    _SectionLabel('Manage'),
                    const SizedBox(height: AppDimens.md),
                    _ActionTile(
                      icon: Icons.menu_book_outlined,
                      title: 'Books',
                      subtitle:
                          '${s.booksTotal} listed'
                          '${s.outOfStock > 0 ? ' · ${s.outOfStock} out of stock' : ''}',
                      onTap: () => context.push(AppRoutes.adminBooks),
                    ),
                    _ActionTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Orders',
                      subtitle: '${s.ordersPending} waiting to be processed',
                      onTap: () => _soon(context, 'Manage Orders'),
                    ),
                    _ActionTile(
                      icon: Icons.people_outline,
                      title: 'Users',
                      subtitle: '${s.usersTotal} registered customers',
                      onTap: () => _soon(context, 'Manage Users'),
                    ),
                    const SizedBox(height: AppDimens.xl),
                    _SectionLabel('Recent orders'),
                    const SizedBox(height: AppDimens.md),
                    if (s.recentOrders.isEmpty)
                      const _EmptyLine('No orders yet.')
                    else
                      ...s.recentOrders.map((o) => _RecentOrderTile(order: o)),
                    const SizedBox(height: AppDimens.xl),
                    _SectionLabel('Top sellers'),
                    const SizedBox(height: AppDimens.md),
                    if (s.topBooks.isEmpty)
                      const _EmptyLine('No sales yet.')
                    else
                      ...s.topBooks.map((b) => _TopBookTile(book: b)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder used only so RefreshIndicator can finish when the fetch fails.
  static final AdminDashboardStats _empty = const AdminDashboardStats(
    revenue: 0,
    ordersTotal: 0,
    ordersPending: 0,
    usersTotal: 0,
    booksTotal: 0,
    lowStock: 0,
    outOfStock: 0,
    recentOrders: [],
    topBooks: [],
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        MediaQuery.of(context).padding.top + AppDimens.md,
        AppDimens.pagePadding,
        AppDimens.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, Color.lerp(c.primary, Colors.black, 0.35)!],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimens.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            'ADMIN',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: c.accent, letterSpacing: 2),
          ),
          const SizedBox(height: 4),
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineLarge
                ?.copyWith(color: AppColors.onPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'A quick look at how Book Haven is doing.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(
        label: 'Revenue',
        value: formatPrice(stats.revenue),
        icon: Icons.payments_outlined,
      ),
      AdminStatCard(
        label: 'Orders',
        value: '${stats.ordersTotal}',
        icon: Icons.shopping_bag_outlined,
      ),
      AdminStatCard(
        label: 'Pending',
        value: '${stats.ordersPending}',
        icon: Icons.hourglass_bottom,
        highlight: stats.ordersPending > 0,
      ),
      AdminStatCard(
        label: 'Customers',
        value: '${stats.usersTotal}',
        icon: Icons.people_outline,
      ),
      AdminStatCard(
        label: 'Books',
        value: '${stats.booksTotal}',
        icon: Icons.menu_book_outlined,
      ),
      AdminStatCard(
        label: 'Low stock',
        value: '${stats.lowStock}',
        icon: Icons.inventory_2_outlined,
        highlight: stats.lowStock > 0,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppDimens.md,
      crossAxisSpacing: AppDimens.md,
      childAspectRatio: 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: c.textSecondary, letterSpacing: 1.5),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Divider(color: c.accent.withValues(alpha: 0.5), height: 1),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppDimens.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: c.primary),
                const SizedBox(width: AppDimens.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});
  final AdminOrderSummary order;

  static String _label(String s) => switch (s) {
    'placed' => 'Placed',
    'processing' => 'Processing',
    'shipped' => 'Shipped',
    'out_for_delivery' => 'Out for delivery',
    'delivered' => 'Delivered',
    'cancelled' => 'Cancelled',
    _ => s,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final color = order.status == 'cancelled'
        ? c.error
        : order.status == 'delivered'
        ? c.primary
        : c.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.customer} · ${DateFormat('d MMM, h:mm a').format(order.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPrice(order.total),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _label(order.status),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBookTile extends StatelessWidget {
  const _TopBookTile({required this.book});
  final AdminTopBook book;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 40,
                height: 56,
                child: book.coverUrl == null
                    ? ColoredBox(color: c.border)
                    : CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            ColoredBox(color: c.border),
                      ),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Text(
              '${book.salesCount} sold',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: c.accent, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: context.palette.textSecondary),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppDimens.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 40, color: c.error),
          const SizedBox(height: AppDimens.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppDimens.lg),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
