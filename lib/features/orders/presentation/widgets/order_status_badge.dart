import 'package:flutter/material.dart';

import 'package:bookhaven/core/theme/app_palette.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final String status;

  static String labelFor(String status) => switch (status) {
    'placed' => 'Placed',
    'processing' => 'Processing',
    'shipped' => 'Shipped',
    'out_for_delivery' => 'Out for delivery',
    'delivered' => 'Delivered',
    'cancelled' => 'Cancelled',
    _ => status,
  };

  static IconData iconFor(String status) => switch (status) {
    'placed' => Icons.receipt_long_outlined,
    'processing' => Icons.inventory_2_outlined,
    'shipped' => Icons.local_shipping_outlined,
    'out_for_delivery' => Icons.delivery_dining_outlined,
    'delivered' => Icons.check_circle_outline,
    'cancelled' => Icons.cancel_outlined,
    _ => Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final color = switch (status) {
      'placed' => c.textSecondary,
      'processing' => c.accent,
      'shipped' || 'out_for_delivery' || 'delivered' => c.primary,
      'cancelled' => c.error,
      _ => c.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(status), size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            labelFor(status),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
