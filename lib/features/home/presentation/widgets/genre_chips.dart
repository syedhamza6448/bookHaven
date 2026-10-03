import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/shared/models/genre.dart';

class GenreChips extends StatelessWidget {
  const GenreChips({super.key, required this.genres, required this.onTap});

  final List<Genre> genres;
  final void Function(Genre genre) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimens.sm),
        itemBuilder: (context, i) {
          final g = genres[i];
          return GestureDetector(
            onTap: () => onTap(g),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.border),
              ),
              child: Text(
                g.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GenreChipsShimmer extends StatelessWidget {
  const GenreChipsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
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
          separatorBuilder: (_, __) => const SizedBox(width: AppDimens.sm),
          itemBuilder: (_, __) => Container(
            width: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
