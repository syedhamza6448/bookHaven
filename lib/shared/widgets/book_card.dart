import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:bookhaven/shared/widgets/book_cover.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.heroPrefix,
    required this.onTap,
    this.width = 140,
  });

  final Book book;

  /// Hero tag = '$heroPrefix-${book.id}'. The prefix keeps tags unique when
  /// the same book appears in two shelves on one screen.
  final String heroPrefix;
  final VoidCallback onTap;
  final double width;

  static String heroTag(String prefix, String bookId) => '$prefix-$bookId';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: heroTag(heroPrefix, book.id),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BookCover(url: book.coverUrl, title: book.title),
                      ),
                    ),
                  ),
                  if (book.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${book.discountPercent}%',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (book.ratingCount > 0)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 13, color: AppColors.star),
                            const SizedBox(width: 3),
                            Text(
                              book.ratingAvg.toStringAsFixed(1),
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              book.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  formatPrice(book.price),
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (book.hasDiscount) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      formatPrice(book.originalPrice!),
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: context.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}