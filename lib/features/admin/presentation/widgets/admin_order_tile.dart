import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/admin/data/admin_order.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrderTile extends StatelessWidget {
  const AdminOrderTile({super.key, required this.order, required this.onTap});

  final AdminOrder order;
  final VoidCallback onTap;

  Color _statusColor(BuildContext context) {
    final c = context.palette;
    return switch (order.status) {
      'placed' || 'processing' => c.accent,
      'cancelled' => c.error,
      _ => c.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final statusColor = _statusColor(context);
    final items = order.itemCount == 1 ? '1 item' : '${order.itemCount} items';
    final payment =
        '${order.isCod ? 'Cash on delivery' : 'Card'} · ${order.isPaid ? 'Paid' : 'Pending'}';

    return Material(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                ),
                child: Icon(Icons.receipt_long_outlined, color: c.primary),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.customerName} · $items',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMM yyyy, h:mm a').format(order.createdAt),
                      style: text.bodySmall?.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: AppDimens.sm),
                    Text(
                      payment,
                      style: text.bodySmall?.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPrice(order.total),
                    style: text.titleMedium?.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AdminOrder.statusLabel(order.status).toUpperCase(),
                      style: text.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
