import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/admin/data/admin_book.dart';

enum _BookAction { edit, delete }

class AdminBookTile extends StatelessWidget {
  const AdminBookTile({
    super.key,
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminBook book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(color: c.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cover(url: book.coverUrl),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium?.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: PopupMenuButton<_BookAction>(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.more_vert,
                              color: c.textSecondary,
                              size: 20,
                            ),
                            color: c.surface,
                            onSelected: (a) =>
                                a == _BookAction.edit ? onEdit() : onDelete(),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: _BookAction.edit,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: c.textPrimary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Edit',
                                      style: TextStyle(color: c.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: _BookAction.delete,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: c.error,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: c.error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (book.isFeatured) ...[
                          Icon(Icons.star_rounded, size: 14, color: c.accent),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            [
                              if (book.genreName.isNotEmpty) book.genreName,
                              '${book.salesCount} sold',
                            ].join('  ·  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          formatPrice(book.price),
                          style: text.titleSmall?.copyWith(
                            color: c.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (book.hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            formatPrice(book.originalPrice!),
                            style: text.bodySmall?.copyWith(
                              color: c.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        const Spacer(),
                        _StockBadge(book: book),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      child: Icon(Icons.menu_book_outlined, color: c.textSecondary),
    );

    return Container(
      width: 60,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url!.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.book});
  final AdminBook book;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final Color color;
    final String label;
    if (book.outOfStock) {
      color = c.error;
      label = 'OUT OF STOCK';
    } else if (book.lowStock) {
      color = c.accent;
      label = '${book.stock} LEFT';
    } else {
      color = c.primary;
      label = '${book.stock} IN STOCK';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
