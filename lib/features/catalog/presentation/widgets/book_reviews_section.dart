import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/catalog/presentation/providers/book_details_providers.dart';
import 'package:bookhaven/features/reviews/data/review_repository.dart';
import 'package:bookhaven/shared/models/review.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BookReviewsSection extends ConsumerStatefulWidget {
  const BookReviewsSection({
    super.key,
    required this.bookId,
    required this.onWriteReview,
  });

  final String bookId;
  final VoidCallback onWriteReview;

  @override
  ConsumerState<BookReviewsSection> createState() => _BookReviewsSectionState();
}

class _BookReviewsSectionState extends ConsumerState<BookReviewsSection> {
  bool _showAll = false;

  Future<void> _toggleLike(Review r) async {
    try {
      await ref
          .read(reviewRepositoryProvider)
          .setLike(r.id, like: !r.likedByMe);
      ref.invalidate(bookReviewsProvider(widget.bookId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update like. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final async = ref.watch(bookReviewsProvider(widget.bookId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'READERS SAY',
              style: text.labelMedium?.copyWith(color: c.accent),
            ),
            const Spacer(),
            TextButton(
              onPressed: widget.onWriteReview,
              child: const Text('Write a review'),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.sm),
        async.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.xl),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.accent,
                ),
              ),
            ),
          ),
          error: (e, st) {
            debugPrint('Reviews load failed: $e\n$st');
            return Row(
              children: [
                Expanded(
                  child: Text(
                    'Could not load reviews.',
                    style: text.bodyMedium?.copyWith(color: c.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(bookReviewsProvider(widget.bookId)),
                  child: const Text('Retry'),
                ),
              ],
            );
          },
          data: (reviews) {
            if (reviews.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.lg),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: c.border),
                ),
                child: Text(
                  'No reviews yet. Be the first to share your thoughts.',
                  style: text.bodyMedium?.copyWith(color: c.textSecondary),
                ),
              );
            }
            final shown = _showAll ? reviews : reviews.take(3).toList();
            return Column(
              children: [
                for (final r in shown)
                  _ReviewTile(review: r, onLike: () => _toggleLike(r)),
                if (reviews.length > 3)
                  TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(
                      _showAll
                          ? 'Show fewer'
                          : 'Show all ${reviews.length} reviews',
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.onLike});
  final Review review;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final initial = review.userName.isEmpty
        ? 'R'
        : review.userName[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.md),
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.accent.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: c.primary,
                  foregroundImage: review.avatarUrl == null
                      ? null
                      : CachedNetworkImageProvider(review.avatarUrl!),
                  onForegroundImageError: review.avatarUrl == null
                      ? null
                      : (_, __) {},
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFFF6F1E7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: text.titleSmall?.copyWith(color: c.textPrimary),
                    ),
                    Text(
                      DateFormat.yMMMd().format(review.createdAt),
                      style: text.bodySmall?.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 16,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppDimens.md),
            Text(
              review.comment,
              style: text.bodyMedium?.copyWith(
                color: c.textPrimary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: AppDimens.sm),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onLike,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      review.likedByMe
                          ? Icons.thumb_up_alt_rounded
                          : Icons.thumb_up_alt_outlined,
                      size: 18,
                      color: review.likedByMe ? c.accent : c.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${review.likeCount}',
                      style: text.bodySmall?.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
