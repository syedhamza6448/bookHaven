import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/admin/data/admin_order.dart';
import 'package:bookhaven/features/admin/data/admin_order_detail.dart';
import 'package:bookhaven/features/admin/data/admin_order_detail_repository.dart';
import 'package:bookhaven/features/admin/presentation/providers/admin_dashboard_providers.dart';
import 'package:bookhaven/features/admin/presentation/providers/admin_order_detail_providers.dart';
import 'package:bookhaven/features/admin/presentation/providers/admin_orders_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends ConsumerState<AdminOrderDetailScreen> {
  final _note = TextEditingController();
  String? _selected;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _apply(AdminOrderDetail d, String status) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminOrderDetailRepositoryProvider)
          .updateStatus(orderId: d.id, status: status, note: _note.text);
      ref.invalidate(adminOrderDetailProvider(widget.orderId));
      ref.read(adminOrdersControllerProvider.notifier).refresh();
      ref.invalidate(adminDashboardProvider);
      _note.clear();
      _selected = null;
      _snack(
        status == 'cancelled'
            ? 'Order cancelled'
            : 'Order marked as ${AdminOrder.statusLabel(status).toLowerCase()}',
      );
    } on AdminOrderActionException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not update the order. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCancel(AdminOrderDetail d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'The books go back into stock and the customer will see the order as cancelled. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Cancel order',
              style: TextStyle(color: ctx.palette.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await _apply(d, 'cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final async = ref.watch(adminOrderDetailProvider(widget.orderId));
    final detail = async.value;

    Widget body;
    if (detail != null) {
      body = _content(context, detail);
    } else if (async.hasError) {
      body = _ErrorView(
        message: async.error is AdminOrderActionException
            ? (async.error as AdminOrderActionException).message
            : 'Could not load this order.',
        onRetry: () => ref.invalidate(adminOrderDetailProvider(widget.orderId)),
      );
    } else {
      body = const _DetailSkeleton();
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          _Header(detail: detail),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, AdminOrderDetail d) {
    final next = d.nextStatuses;
    final selected = (next.contains(_selected)
        ? _selected
        : (next.isEmpty ? null : next.first));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminOrderDetailProvider(widget.orderId));
        await ref.read(adminOrderDetailProvider(widget.orderId).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadding,
          AppDimens.lg,
          AppDimens.pagePadding,
          AppDimens.xxl,
        ),
        children: [
          _CustomerCard(detail: d),
          const SizedBox(height: AppDimens.lg),
          _StatusCard(
            detail: d,
            selected: selected,
            note: _note,
            busy: _busy,
            onSelect: (s) => setState(() => _selected = s),
            onUpdate: selected == null ? null : () => _apply(d, selected),
            onCancel: () => _confirmCancel(d),
          ),
          const SizedBox(height: AppDimens.lg),
          _ItemsCard(detail: d),
          const SizedBox(height: AppDimens.lg),
          _InfoCard(
            title: 'DELIVERING TO',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in d.addressLines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.lg),
          _PaymentCard(detail: d),
          const SizedBox(height: AppDimens.lg),
          _HistoryCard(detail: d),
        ],
      ),
    );
  }
}

// ───────────────────────── Header ─────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final AdminOrderDetail? detail;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
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
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER',
                  style: text.labelMedium?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  detail?.orderNumber ?? '…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail != null)
                  Text(
                    DateFormat('d MMM yyyy, h:mm a').format(detail!.createdAt),
                    style: text.bodySmall?.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
          if (detail != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AdminOrder.statusLabel(detail!.status).toUpperCase(),
                style: text.labelSmall?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Cards ─────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

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
                ?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppDimens.md),
          child,
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.detail});

  final AdminOrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final initial = detail.customerName.isEmpty
        ? '?'
        : detail.customerName[0].toUpperCase();
    final avatar = detail.customerAvatarUrl;

    return _InfoCard(
      title: 'CUSTOMER',
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: c.primary.withValues(alpha: 0.12),
            backgroundImage: (avatar != null && avatar.isNotEmpty)
                ? CachedNetworkImageProvider(avatar)
                : null,
            child: (avatar == null || avatar.isEmpty)
                ? Text(
                    initial,
                    style: text.titleMedium?.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.customerName,
                  style: text.titleSmall?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detail.customerEmail != null)
                  Text(
                    detail.customerEmail!,
                    style: text.bodySmall?.copyWith(color: c.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.detail,
    required this.selected,
    required this.note,
    required this.busy,
    required this.onSelect,
    required this.onUpdate,
    required this.onCancel,
  });

  final AdminOrderDetail detail;
  final String? selected;
  final TextEditingController note;
  final bool busy;
  final ValueChanged<String> onSelect;
  final VoidCallback? onUpdate;
  final VoidCallback onCancel;

  String _hint(String status) => switch (status) {
    'processing' => 'The books are being packed',
    'shipped' => 'Handed over to the courier',
    'out_for_delivery' => 'On its way to the customer',
    'delivered' =>
      detail.isCod
          ? 'Completed, cash payment is marked as received'
          : 'Order completed',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    if (detail.isTerminal) {
      final cancelled = detail.status == 'cancelled';
      return _InfoCard(
        title: 'STATUS',
        child: Row(
          children: [
            Icon(
              cancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
              color: cancelled ? c.error : c.primary,
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Text(
                cancelled
                    ? 'This order was cancelled. No further changes can be made.'
                    : 'This order was delivered. No further changes can be made.',
                style: text.bodyMedium?.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return _InfoCard(
      title: 'UPDATE STATUS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in detail.nextStatuses)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                onTap: busy ? null : () => onSelect(s),
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                    border: Border.all(
                      color: s == selected ? c.primary : c.border,
                      width: s == selected ? 1.6 : 1,
                    ),
                    color: s == selected
                        ? c.primary.withValues(alpha: 0.06)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        s == selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: s == selected ? c.primary : c.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimens.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AdminOrder.statusLabel(s),
                              style: text.titleSmall?.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _hint(s),
                              style: text.bodySmall?.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppDimens.xs),
          TextField(
            controller: note,
            enabled: !busy,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Add a note for the timeline (optional)',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppDimens.md),
          SizedBox(
            width: double.infinity,
            height: AppDimens.buttonHeight,
            child: FilledButton(
              onPressed: (busy || onUpdate == null) ? null : onUpdate,
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      selected == null
                          ? 'Update status'
                          : 'Mark as ${AdminOrder.statusLabel(selected!).toLowerCase()}',
                    ),
            ),
          ),
          const SizedBox(height: AppDimens.xs),
          Center(
            child: TextButton(
              onPressed: busy ? null : onCancel,
              child: Text(
                'Cancel this order',
                style: TextStyle(color: c.error, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.detail});

  final AdminOrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final count = detail.itemCount;

    return _InfoCard(
      title: 'ITEMS · $count',
      child: Column(
        children: [
          for (var i = 0; i < detail.lines.length; i++) ...[
            if (i > 0) Divider(height: AppDimens.xl, color: c.border),
            _LineRow(line: detail.lines[i], text: text),
          ],
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.text});

  final AdminOrderLine line;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 44,
            height: 62,
            child: (line.coverUrl == null || line.coverUrl!.isEmpty)
                ? Container(
                    color: c.border,
                    child: Icon(
                      Icons.menu_book_outlined,
                      color: c.textSecondary,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: line.coverUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: c.border,
                      child: Icon(
                        Icons.menu_book_outlined,
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
                line.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                line.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '${line.quantity} × ${formatPrice(line.unitPrice)}',
                style: text.bodySmall?.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.sm),
        Text(
          formatPrice(line.lineTotal),
          style: text.titleSmall?.copyWith(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.detail});

  final AdminOrderDetail detail;

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool strong = false,
  }) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (strong ? text.titleSmall : text.bodyMedium)?.copyWith(
              color: strong ? c.textPrimary : c.textSecondary,
              fontWeight: strong ? FontWeight.w700 : null,
            ),
          ),
          Text(
            value,
            style: (strong ? text.titleMedium : text.bodyMedium)?.copyWith(
              color: c.textPrimary,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final method = detail.isCod
        ? 'Cash on delivery'
        : 'Card${detail.cardLast4 == null ? '' : ' •••• ${detail.cardLast4}'}';

    return _InfoCard(
      title: 'PAYMENT',
      child: Column(
        children: [
          _row(context, 'Method', method),
          _row(context, 'Status', detail.isPaid ? 'Paid' : 'Pending'),
          Divider(height: AppDimens.xl, color: c.border),
          _row(context, 'Subtotal', formatPrice(detail.subtotal)),
          _row(
            context,
            'Delivery',
            detail.deliveryFee == 0 ? 'Free' : formatPrice(detail.deliveryFee),
          ),
          const SizedBox(height: AppDimens.xs),
          _row(context, 'Total', formatPrice(detail.total), strong: true),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.detail});

  final AdminOrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    return _InfoCard(
      title: 'STATUS HISTORY',
      child: Column(
        children: [
          for (var i = 0; i < detail.history.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0 ? c.accent : c.border,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AdminOrder.statusLabel(detail.history[i].status),
                          style: text.titleSmall?.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((detail.history[i].note ?? '').isNotEmpty)
                          Text(
                            detail.history[i].note!,
                            style: text.bodySmall?.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        Text(
                          DateFormat('d MMM yyyy, h:mm a')
                              .format(detail.history[i].createdAt),
                          style: text.bodySmall?.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
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

// ───────────────────────── States ─────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Shimmer.fromColors(
      baseColor: c.border,
      highlightColor: c.surface,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.pagePadding),
        children: [
          for (final h in [90.0, 230.0, 160.0, 110.0])
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.lg),
              child: Container(
                height: h,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: c.error),
            const SizedBox(height: AppDimens.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppDimens.lg),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
