import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:bookhaven/shared/widgets/book_card.dart';
import 'package:bookhaven/shared/widgets/inline_error.dart';

const double _shelfHeight = 324;

class BookShelf extends StatelessWidget {
  const BookShelf({
    super.key,
    required this.books,
    required this.heroPrefix,
    required this.onBookTap,
    required this.onRetry,
  });

  final AsyncValue<List<Book>> books;
  final String heroPrefix;
  final void Function(Book book) onBookTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return books.when(
      loading: () => const _ShelfShimmer(),
      error: (_, __) =>
          InlineError(message: "Couldn't load books.", onRetry: onRetry),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.pagePadding,
            ),
            child: Text(
              'No books yet.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.textSecondary),
            ),
          );
        }
        return SizedBox(
          height: _shelfHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.pagePadding,
            ),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppDimens.lg),
            itemBuilder: (context, i) =>
                BookCard(
                      book: list[i],
                      heroPrefix: heroPrefix,
                      onTap: () => onBookTap(list[i]),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (60 * i).ms)
                    .slideX(begin: 0.1, curve: Curves.easeOut),
          ),
        );
      },
    );
  }
}

class _ShelfShimmer extends StatelessWidget {
  const _ShelfShimmer();

  Widget _box(double w, double h, {double r = 6}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _shelfHeight,
      child: Shimmer.fromColors(
        baseColor: context.border,
        highlightColor: context.surface,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.pagePadding,
          ),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: AppDimens.lg),
          itemBuilder: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(140, 210, r: 8),
              const SizedBox(height: 10),
              _box(110, 14),
              const SizedBox(height: 6),
              _box(80, 12),
            ],
          ),
        ),
      ),
    );
  }
}
