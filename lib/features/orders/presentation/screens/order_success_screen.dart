import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/orders/presentation/providers/order_providers.dart';
import 'package:bookhaven/shared/models/order.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _parchment = Color(0xFFF6F1E7);

class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    this.orderNumber,
  });

  final String orderId;
  final String? orderNumber;

  void _goHome(BuildContext context) => context.go(AppRoutes.home);

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Order history is coming soon')),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final async = ref.watch(orderProvider(orderId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: async.when(
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: c.primary),
                if (orderNumber != null) ...[
                  const SizedBox(height: AppDimens.lg),
                  Text(
                    'Order $orderNumber',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          // The order is already placed, so even if the fetch fails we reassure the user.
          error: (e, _) => _FallbackView(
            orderNumber: orderNumber,
            onRetry: () => ref.invalidate(orderProvider(orderId)),
            onContinue: () => _goHome(context),
          ),
          data: (order) => Column(
            children: [
              Expanded(child: _OrderBody(order: order)),
              _BottomBar(
                onOrders: () => _comingSoon(context),
                onContinue: () => _goHome(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Body ─────────────────────────

class _OrderBody extends StatelessWidget {
  const _OrderBody({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _OrderNumberCard(order: order),
      _DeliveryEstimate(order: order),
      _ItemsCard(order: order),
      _AddressCard(order: order),
      _PaymentCard(order: order),
      _TotalsCard(order: order),
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _SuccessHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.pagePadding,
            AppDimens.xl,
            AppDimens.pagePadding,
            AppDimens.xl,
          ),
          child: Column(
            children: sections
                .map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.lg),
                    child: w,
                  ),
                )
                .toList()
                .animate(interval: 90.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Header ─────────────────────────

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        MediaQuery.of(context).padding.top + AppDimens.xxl,
        AppDimens.pagePadding,
        AppDimens.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, Color.lerp(c.primary, Colors.black, 0.4)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // soft pulsing ring
                Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.accent.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                    )
                    .animate(onPlay: (ctl) => ctl.repeat())
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.1, 1.1),
                      duration: 1800.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeOut(duration: 1800.ms),
                Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: Color(0xFF1C1A17),
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.2, 0.2),
                      end: const Offset(1, 1),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 250.ms),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.lg),
          Text(
                'Thank you.',
                style: text.displaySmall?.copyWith(color: _parchment),
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: AppDimens.sm),
          Text(
            'Your order is confirmed and your\nbooks are being prepared.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: _parchment.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
          const SizedBox(height: AppDimens.lg),
          Container(
            width: 56,
            height: 2,
            color: c.accent,
          ).animate().scaleX(delay: 600.ms, duration: 500.ms, begin: 0, end: 1),
        ],
      ),
    );
  }
}

// ───────────────────────── Cards ─────────────────────────

class _Card extends StatelessWidget {
  const _Card({this.title, required this.child});
  final String? title;
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
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppDimens.md),
          ],
          child,
        ],
      ),
    );
  }
}

class _OrderNumberCard extends StatelessWidget {
  const _OrderNumberCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    return _Card(
      title: 'ORDER NUMBER',
      child: Row(
        children: [
          Expanded(
            child: Text(
              order.orderNumber,
              style: text.titleLarge?.copyWith(
                color: c.textPrimary,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: Icon(Icons.copy_rounded, size: 20, color: c.primary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: order.orderNumber));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Order number copied')),
                );
            },
          ),
        ],
      ),
    );
  }
}

class _DeliveryEstimate extends StatelessWidget {
  const _DeliveryEstimate({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    return _Card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_shipping_outlined, color: c.accent),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated delivery',
                  style: text.bodySmall?.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  order.deliveryWindow,
                  style: text.titleSmall?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final count = order.itemCount;

    return _Card(
      title: 'YOUR BOOKS ($count ${count == 1 ? 'ITEM' : 'ITEMS'})',
      child: Column(
        children: [
          for (var i = 0; i < order.items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                child: Divider(height: 1, color: c.border),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 48,
                    height: 70,
                    child: order.items[i].coverUrl == null
                        ? ColoredBox(
                            color: c.border,
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: c.textSecondary,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: order.items[i].coverUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => ColoredBox(
                              color: c.border,
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.items[i].title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.items[i].authorName,
                        style: text.bodySmall?.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${order.items[i].quantity} × ${formatPrice(order.items[i].unitPrice)}',
                        style: text.bodySmall?.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                Text(
                  formatPrice(order.items[i].lineTotal),
                  style: text.titleSmall?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    return _Card(
      title: 'DELIVERING TO',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: c.primary, size: 22),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.shipFullName,
                  style: text.titleSmall?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                for (final line in order.addressLines)
                  Text(
                    line,
                    style: text.bodyMedium?.copyWith(
                      color: c.textSecondary,
                      height: 1.4,
                    ),
                  ),
                if (order.shipPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.shipPhone,
                    style: text.bodyMedium?.copyWith(color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    final title = order.isCod
        ? 'Cash on Delivery'
        : 'Card ending ${order.cardLast4 ?? '••••'}';
    final subtitle = order.isCod
        ? 'Pay when your books arrive'
        : (order.isPaid ? 'Payment received' : 'Payment pending');

    return _Card(
      title: 'PAYMENT',
      child: Row(
        children: [
          Icon(
            order.isCod ? Icons.payments_outlined : Icons.credit_card_rounded,
            color: c.primary,
            size: 22,
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleSmall?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (order.isPaid ? c.primary : c.accent).withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.isPaid ? 'PAID' : 'PENDING',
              style: text.labelSmall?.copyWith(
                color: order.isPaid ? c.primary : c.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    Widget row(
      String label,
      String value, {
      bool bold = false,
      Color? valueColor,
    }) {
      final style = (bold ? text.titleMedium : text.bodyMedium)?.copyWith(
        color: bold ? c.textPrimary : c.textSecondary,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      );
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style?.copyWith(color: valueColor ?? style.color)),
        ],
      );
    }

    return _Card(
      title: 'SUMMARY',
      child: Column(
        children: [
          row('Subtotal', formatPrice(order.subtotal)),
          const SizedBox(height: AppDimens.sm),
          row(
            'Delivery',
            order.deliveryFee == 0 ? 'Free' : formatPrice(order.deliveryFee),
            valueColor: order.deliveryFee == 0 ? c.primary : null,
          ),
          const SizedBox(height: AppDimens.md),
          Divider(height: 1, color: c.accent.withValues(alpha: 0.6)),
          const SizedBox(height: AppDimens.md),
          row('Total', formatPrice(order.total), bold: true),
        ],
      ),
    );
  }
}

// ───────────────────────── Bottom bar ─────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onOrders, required this.onContinue});
  final VoidCallback onOrders;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        AppDimens.md,
        AppDimens.pagePadding,
        MediaQuery.of(context).padding.bottom + AppDimens.md,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: AppDimens.buttonHeight,
              child: OutlinedButton(
                onPressed: onOrders,
                child: const Text('My orders'),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: AppDimens.buttonHeight,
              child: ElevatedButton(
                onPressed: onContinue,
                child: const Text('Continue shopping'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Fallback ─────────────────────────

class _FallbackView extends StatelessWidget {
  const _FallbackView({
    required this.orderNumber,
    required this.onRetry,
    required this.onContinue,
  });

  final String? orderNumber;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: c.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 48,
                color: Color(0xFF1C1A17),
              ),
            ),
            const SizedBox(height: AppDimens.xl),
            Text('Order placed', style: text.headlineMedium),
            if (orderNumber != null) ...[
              const SizedBox(height: AppDimens.sm),
              Text(
                orderNumber!,
                style: text.titleMedium?.copyWith(letterSpacing: 1),
              ),
            ],
            const SizedBox(height: AppDimens.md),
            Text(
              "We couldn't load the order details right now, but your order is safe.",
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppDimens.xl),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            const SizedBox(height: AppDimens.md),
            ElevatedButton(
              onPressed: onContinue,
              child: const Text('Continue shopping'),
            ),
          ],
        ),
      ),
    );
  }
}
