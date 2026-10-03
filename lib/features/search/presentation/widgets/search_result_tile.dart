import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.book,
    required this.heroTag,
    required this.onTap,
  });

  final Book book;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final cover = book.coverUrl ?? '';
    final author = book.authorName ?? '';
    final genre = book.genreName ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusInput),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: heroTag,
              child: Container(
                width: 70,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: cover.isEmpty
                      ? Container(
                          color: c.border,
                          child: Icon(
                            Icons.menu_book_outlined,
                            color: c.textSecondary,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: c.border),
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
            ),
            const SizedBox(width: AppDimens.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (genre.isNotEmpty)
                    Text(
                      genre.toUpperCase(),
                      style: t.labelMedium?.copyWith(
                        color: c.accent,
                        fontSize: 10,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(
                      color: c.textPrimary,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: c.accent),
                      const SizedBox(width: 3),
                      Text(
                        book.ratingAvg.toStringAsFixed(1),
                        style: t.bodySmall?.copyWith(color: c.textPrimary),
                      ),
                      Text(
                        '  (${book.ratingCount})',
                        style: t.bodySmall?.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Row(
                    children: [
                      Text(
                        formatPrice(book.price),
                        style: t.titleMedium?.copyWith(color: c.primary),
                      ),
                      if (book.originalPrice != null && book.hasDiscount) ...[
                        const SizedBox(width: AppDimens.sm),
                        Text(
                          formatPrice(book.originalPrice!),
                          style: t.bodySmall?.copyWith(
                            color: c.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: AppDimens.sm),
                        Text(
                          '-${book.discountPercent}%',
                          style: t.bodySmall?.copyWith(color: c.error),
                        ),
                      ],
                      const Spacer(),
                      if (!book.inStock)
                        Text(
                          'OUT OF STOCK',
                          style: t.labelMedium?.copyWith(
                            color: c.error,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
