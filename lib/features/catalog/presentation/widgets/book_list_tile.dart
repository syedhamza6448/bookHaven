import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookListTile extends StatelessWidget {
  const BookListTile({
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: heroTag,
              child: Container(
                width: 88,
                height: 132,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: book.coverUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ColoredBox(color: context.border),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: context.border,
                      child: Icon(Icons.auto_stories, color: context.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 132,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (book.genreName ?? '').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        color: context.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.authorName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: 12.5, color: context.textSecondary),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
                        const SizedBox(width: 3),
                        Text(
                          book.ratingCount == 0
                              ? 'New'
                              : '${book.ratingAvg.toStringAsFixed(1)} (${book.ratingCount})',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(book.price),
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.primary,
                          ),
                        ),
                        if (book.hasDiscount && book.originalPrice != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            formatPrice(book.originalPrice!),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '-${book.discountPercent}%',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.error,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (!book.inStock)
                          Text(
                            'Sold out',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}