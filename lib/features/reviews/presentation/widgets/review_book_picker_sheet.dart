import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';

class ReviewTarget {
  const ReviewTarget({
    required this.bookId,
    required this.title,
    required this.authorName,
    this.coverUrl,
  });

  final String bookId;
  final String title;
  final String authorName;
  final String? coverUrl;
}

/// One book opens Write Review directly; several show a picker first.
Future<void> startReview(
  BuildContext context,
  List<ReviewTarget> targets,
) async {
  if (targets.isEmpty) return;

  ReviewTarget? picked = targets.length == 1
      ? targets.first
      : await _pick(context, targets);
  if (picked == null || !context.mounted) return;

  await context.push<bool>(
    AppRoutes.writeReviewPath(
      picked.bookId,
      title: picked.title,
      author: picked.authorName,
      cover: picked.coverUrl,
    ),
  );
}

Future<ReviewTarget?> _pick(BuildContext context, List<ReviewTarget> targets) {
  final c = context.palette;
  final theme = Theme.of(context);

  return showModalBottomSheet<ReviewTarget>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: c.surface,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadding,
              0,
              AppDimens.pagePadding,
              AppDimens.md,
            ),
            child: Text(
              'Which book would you like to review?',
              style: theme.textTheme.titleLarge?.copyWith(color: c.textPrimary),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: AppDimens.lg),
              itemCount: targets.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: c.border, indent: 84),
              itemBuilder: (_, i) {
                final t = targets[i];
                final url = t.coverUrl;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.pagePadding,
                    vertical: 4,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 40,
                      height: 60,
                      child: (url == null || url.isEmpty)
                          ? ColoredBox(color: c.border)
                          : CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  ColoredBox(color: c.border),
                            ),
                    ),
                  ),
                  title: Text(
                    t.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    t.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: c.textSecondary,
                  ),
                  onTap: () => Navigator.pop(ctx, t),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
