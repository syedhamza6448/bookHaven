import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/orders/presentation/widgets/order_status_badge.dart';
import 'package:bookhaven/shared/models/order.dart';

class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final items = order.items;
    final radius = BorderRadius.circular(AppDimens.radiusCard);

    final title = items.isEmpty
        ? 'Your order'
        : items.length == 1
        ? items.first.title
        : '${items.first.title} + ${items.length - 1} more';

    final date = DateFormat('d MMM yyyy').format(order.createdAt.toLocal());
    final countLabel = order.itemCount == 1
        ? '1 item'
        : '${order.itemCount} items';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.25 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: c.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.orderNumber}',
                            style: t.titleMedium?.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Placed $date',
                            style: t.bodySmall?.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                Container(height: 1, color: c.border),
                const SizedBox(height: AppDimens.md),
                Row(
                  children: [
                    _CoverStack(
                      urls: [
                        for (final i in items.take(3)) i.coverUrl as String?,
                      ],
                    ),
                    const SizedBox(width: AppDimens.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleSmall?.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$countLabel · ${order.isCod ? 'Cash on delivery' : 'Card'}',
                            style: t.bodySmall?.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                Row(
                  children: [
                    Text(
                      'TOTAL',
                      style: t.labelMedium?.copyWith(
                        color: c.textSecondary,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    Text(
                      formatPrice(order.total),
                      style: t.titleMedium?.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'View details',
                      style: t.labelLarge?.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: c.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverStack extends StatelessWidget {
  const _CoverStack({required this.urls});

  final List<String?> urls;

  static const double _w = 44;
  static const double _h = 64;
  static const double _step = 18;

  @override
  Widget build(BuildContext context) {
    final n = urls.isEmpty ? 1 : urls.length;
    return SizedBox(
      width: _w + (n - 1) * _step,
      height: _h,
      child: Stack(
        children: [
          // Paint from the back so the first book ends up on top.
          for (var i = n - 1; i >= 0; i--)
            Positioned(
              left: i * _step,
              child: _Cover(url: urls.isEmpty ? null : urls[i]),
            ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final placeholder = Container(
      color: c.border,
      alignment: Alignment.center,
      child: Icon(Icons.menu_book_rounded, size: 18, color: c.textSecondary),
    );

    return Container(
      width: _CoverStack._w,
      height: _CoverStack._h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.surface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: (url == null || url!.isEmpty)
            ? placeholder
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => placeholder,
                errorWidget: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}
