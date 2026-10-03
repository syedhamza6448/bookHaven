import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/catalog/presentation/providers/book_details_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RelatedBooksRow extends ConsumerWidget {
  const RelatedBooksRow({
    super.key,
    required this.bookId,
    required this.genreId,
    required this.genreName,
  });

  final String bookId;
  final String? genreId;
  final String genreName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final async = ref.watch(
      relatedBooksProvider((bookId: bookId, genreId: genreId)),
    );

    return async.maybeWhen(
      data: (books) {
        if (books.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.pagePadding,
              ),
              child: Text(
                'MORE IN ${genreName.toUpperCase()}',
                style: text.labelMedium?.copyWith(color: c.accent),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            SizedBox(
              height: 232,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.pagePadding,
                ),
                itemCount: books.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppDimens.lg),
                itemBuilder: (context, i) {
                  final b = books[i];
                  final tag = 'related-${b.id}';
                  return GestureDetector(
                    onTap: () => context.push(
                      AppRoutes.bookDetailsPath('${b.id}', heroTag: tag),
                    ),
                    child: SizedBox(
                      width: 110,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: tag,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: b.coverUrl ?? '',
                                  width: 110,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Container(
                                    width: 110,
                                    height: 160,
                                    color: c.border,
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimens.sm),
                          Text(
                            b.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formatPrice(b.price),
                            style: text.bodySmall?.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
