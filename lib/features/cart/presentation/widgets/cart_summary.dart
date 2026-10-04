import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/shared/models/cart_item.dart';
import 'package:flutter/material.dart';

class CartSummary extends StatelessWidget {
  const CartSummary({
    super.key,
    required this.totals,
    required this.onCheckout,
  });

  final CartTotals totals;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final freeLeft = totals.amountToFreeDelivery;
    final progress = (totals.subtotal / CartTotals.freeDeliveryThreshold).clamp(
      0.0,
      1.0,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        AppDimens.lg,
        AppDimens.pagePadding,
        AppDimens.lg,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (freeLeft > 0) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add ${formatPrice(freeLeft.toDouble())} more for free delivery',
                  style: text.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: c.border,
                  color: c.accent,
                ),
              ),
              const SizedBox(height: AppDimens.md),
            ],
            _Row(label: 'Subtotal', value: formatPrice(totals.subtotal)),
            const SizedBox(height: 6),
            _Row(
              label: 'Delivery',
              value: totals.delivery == 0
                  ? 'Free'
                  : formatPrice(totals.delivery),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
              child: Divider(height: 1, color: c.accent.withValues(alpha: 0.5)),
            ),
            _Row(label: 'Total', value: formatPrice(totals.total), bold: true),
            const SizedBox(height: AppDimens.lg),
            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: FilledButton(
                onPressed: onCheckout,
                child: const Text('Proceed to checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});
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
