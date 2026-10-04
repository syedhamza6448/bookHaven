import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/constants/shop_rules.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/shared/models/cart_item.dart';

double cartSubtotal(List<CartItem> items) =>
    items.fold<double>(0, (s, i) => s + i.lineTotal.toDouble());

class CheckoutSummary extends StatelessWidget {
  const CheckoutSummary({super.key, required this.items});
  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final subtotal = cartSubtotal(items);
    final delivery = ShopRules.deliveryFor(subtotal);

    Widget row(String label, String value, {bool bold = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: (bold ? text.titleMedium : text.bodyMedium)?.copyWith(
                  color: bold ? c.textPrimary : c.textSecondary,
                ),
              ),
              Text(
                value,
                style: (bold ? text.titleMedium : text.bodyMedium)?.copyWith(
                  color: color ?? c.textPrimary,
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.md),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 38,
                      height: 56,
                      child: CachedNetworkImage(
                        imageUrl: item.book.coverUrl ?? '',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: c.border,
                          child: Icon(
                            Icons.menu_book_outlined,
                            size: 18,
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
                          item.book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          'Qty ${item.quantity} × ${formatPrice(item.book.price)}',
                          style: text.bodySmall?.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatPrice(item.lineTotal.toDouble()),
                    style: text.bodyMedium?.copyWith(color: c.textPrimary),
                  ),
                ],
              ),
            ),
          Container(height: 1, color: c.accent.withValues(alpha: 0.4)),
          const SizedBox(height: AppDimens.sm),
          row('Subtotal', formatPrice(subtotal)),
          row(
            'Delivery',
            delivery == 0 ? 'FREE' : formatPrice(delivery),
            color: delivery == 0 ? c.primary : null,
          ),
          const SizedBox(height: AppDimens.xs),
          row('Total', formatPrice(subtotal + delivery), bold: true),
        ],
      ),
    );
  }
}
