import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/cart/presentation/providers/cart_controller.dart';
import 'package:bookhaven/features/orders/data/order_details_repository.dart';
import 'package:bookhaven/features/orders/presentation/providers/order_details_providers.dart';
import 'package:bookhaven/features/orders/presentation/providers/order_history_controller.dart';
import 'package:bookhaven/features/orders/presentation/providers/order_providers.dart';
import 'package:bookhaven/features/orders/presentation/widgets/order_status_badge.dart';
import 'package:bookhaven/features/orders/presentation/widgets/order_tracking_timeline.dart';
import 'package:bookhaven/features/profile/presentation/providers/profile_providers.dart';
import 'package:bookhaven/shared/models/order.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _busy = false;

  static const _cancellable = {'placed', 'processing'};

  Future<void> _refresh() async {
    ref.invalidate(orderProvider(widget.orderId));
    ref.invalidate(orderStatusHistoryProvider(widget.orderId));
    try {
      await ref.read(orderProvider(widget.orderId).future);
    } catch (_) {}
  }

  void _snack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  Future<void> _cancel(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'Your books will be released and the order cannot be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(orderDetailsRepositoryProvider).cancelOrder(order.id);
      ref.invalidate(orderProvider(order.id));
      ref.invalidate(orderStatusHistoryProvider(order.id));
      ref.invalidate(orderHistoryControllerProvider);
      ref.invalidate(profileStatsProvider);
      if (mounted) _snack('Order cancelled.');
    } on OrderActionException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('Could not cancel the order. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buyAgain(Order order) async {
    setState(() => _busy = true);
    try {
      final added = await ref
          .read(orderDetailsRepositoryProvider)
          .reorder(order.id);
      ref.invalidate(cartControllerProvider);
      if (!mounted) return;
      if (added == 0) {
        _snack('These books are currently out of stock.');
      } else {
        _snack(
          added == 1
              ? '1 book added to your cart.'
              : '$added books added to your cart.',
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () => context.go(AppRoutes.cart),
          ),
        );
      }
    } on OrderActionException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('Could not add these books. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final orderAsync = ref.watch(orderProvider(widget.orderId));

    return Scaffold(
      backgroundColor: c.bg,
      body: orderAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: c.primary)),
        error: (e, _) => _ErrorView(onRetry: _refresh),
        data: (order) => _buildContent(context, order),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Order order) {
    final c = context.palette;
    final historyAsync = ref.watch(orderStatusHistoryProvider(order.id));
    final events = historyAsync.value ?? const [];
    final isActive = order.status != 'delivered' && order.status != 'cancelled';
    final canCancel = _cancellable.contains(order.status);
    final dateText = DateFormat('d MMM yyyy, h:mm a').format(order.createdAt);

    final sections = <Widget>[
      _Section(
        title: 'DELIVERY TRACKING',
        child: historyAsync.isLoading && events.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: c.primary),
                ),
              )
            : OrderTrackingTimeline(status: order.status, events: events),
      ),
      if (isActive)
        _Section(
          title: 'ESTIMATED DELIVERY',
          child: Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: c.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order.deliveryWindow,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      _Section(
        title: 'ITEMS (${order.itemCount})',
        child: Column(
          children: [
            for (var i = 0; i < order.items.length; i++) ...[
              if (i > 0) Divider(height: 20, thickness: 1, color: c.border),
              _ItemRow(item: order.items[i]),
            ],
          ],
        ),
      ),
      _Section(
        title: 'DELIVERING TO',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                order.addressLines.join('\n'),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
      _Section(
        title: 'PAYMENT',
        child: Row(
          children: [
            Icon(
              order.isCod ? Icons.payments_outlined : Icons.credit_card,
              color: c.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                order.isCod
                    ? 'Cash on Delivery'
                    : 'Card ending ${order.cardLast4 ?? '••••'}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (order.isPaid ? c.primary : c.accent).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                order.isPaid ? 'PAID' : 'PENDING',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: order.isPaid ? c.primary : c.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
      _Section(
        title: 'SUMMARY',
        child: Column(
          children: [
            _SummaryRow('Subtotal', formatPrice(order.subtotal)),
            const SizedBox(height: 8),
            _SummaryRow(
              'Delivery',
              order.deliveryFee == 0 ? 'Free' : formatPrice(order.deliveryFee),
            ),
            Divider(height: 24, thickness: 1, color: c.border),
            _SummaryRow('Total', formatPrice(order.total), bold: true),
          ],
        ),
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: c.primary,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(order: order, dateText: dateText),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.pagePadding,
                    AppDimens.lg,
                    AppDimens.pagePadding,
                    AppDimens.xl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: sections.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimens.lg),
                    itemBuilder: (_, i) => sections[i]
                        .animate()
                        .fadeIn(delay: (60 * i).ms, duration: 350.ms)
                        .slideY(begin: 0.04, end: 0),
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomBar(
          busy: _busy,
          canCancel: canCancel,
          delivered: order.status == 'delivered',
          onCancel: () => _cancel(order),
          onBuyAgain: () => _buyAgain(order),
          onReview: () => _snack('Reviews are coming next.'),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order, required this.dateText});

  final Order order;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final top = MediaQuery.of(context).padding.top;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        top + 8,
        AppDimens.pagePadding,
        AppDimens.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, c.primary.withValues(alpha: 0.82)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.orders),
            icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 8),
          Text(
            'ORDER DETAILS',
            style: text.labelMedium?.copyWith(color: c.accent),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: order.orderNumber));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Order number copied')),
                );
            },
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    order.orderNumber,
                    style: text.headlineSmall?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: AppColors.onPrimary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Placed $dateText',
            style: text.bodySmall?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 14),
          OrderStatusBadge(status: order.status),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: c.accent),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            width: 36,
            margin: const EdgeInsets.only(bottom: 14, top: 6),
            color: c.accent,
          ),
          child,
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final url = item.coverUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push(AppRoutes.bookDetailsPath(item.bookId)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 68,
              child: (url == null || url.isEmpty)
                  ? Container(
                      color: c.border,
                      child: Icon(Icons.menu_book, color: c.textSecondary),
                    )
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: c.border,
                        child: Icon(Icons.menu_book, color: c.textSecondary),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  item.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × ${formatPrice(item.unitPrice)}',
                  style: text.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatPrice(item.unitPrice * item.quantity),
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final style = bold
        ? text.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : text.bodyMedium?.copyWith(color: c.textSecondary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.busy,
    required this.canCancel,
    required this.delivered,
    required this.onCancel,
    required this.onBuyAgain,
    required this.onReview,
  });

  final bool busy;
  final bool canCancel;
  final bool delivered;
  final VoidCallback onCancel;
  final VoidCallback onBuyAgain;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        12,
        AppDimens.pagePadding,
        12 + bottom,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          if (canCancel) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
                  foregroundColor: c.error,
                  side: BorderSide(color: c.error.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                  ),
                ),
                child: const Text('Cancel order'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (delivered) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : onReview,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
                  foregroundColor: c.primary,
                  side: BorderSide(color: c.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                  ),
                ),
                child: const Text('Write a review'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: busy ? null : onBuyAgain,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buy again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: c.error),
              const SizedBox(height: 12),
              Text(
                'Could not load this order',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
              TextButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.orders),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
