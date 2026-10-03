import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookGridCard extends StatelessWidget {
  const BookGridCard({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Hero(
              tag: heroTag,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: context.isDark ? 0.35 : 0.16,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: book.coverUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            ColoredBox(color: context.border),
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: context.border,
                          child: Icon(
                            Icons.auto_stories,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                      if (book.hasDiscount)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _Badge(
                            text: '-${book.discountPercent}%',
                            color: context.error,
                          ),
                        ),
                      if (!book.inStock)
                        Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          alignment: Alignment.center,
                          child: Text(
                            'SOLD OUT',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 17,
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
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 15, color: AppColors.star),
              const SizedBox(width: 2),
              Text(
                book.ratingCount == 0
                    ? 'New'
                    : book.ratingAvg.toStringAsFixed(1),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                formatPrice(book.price),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
