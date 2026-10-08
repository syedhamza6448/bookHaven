import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/reviews/data/my_review_repository.dart';
import 'package:bookhaven/features/reviews/presentation/providers/my_review_providers.dart';
import 'package:bookhaven/features/reviews/presentation/providers/review_submit_controller.dart';
import 'package:bookhaven/features/reviews/presentation/widgets/star_rating_input.dart';

class WriteReviewScreen extends ConsumerWidget {
  const WriteReviewScreen({
    super.key,
    required this.bookId,
    required this.title,
    required this.authorName,
    this.coverUrl,
  });

  final String bookId;
  final String title;
  final String authorName;
  final String? coverUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = ref.watch(myReviewProvider(bookId));

    // If loading the old review fails we still let the user write one.
    return existing.when(
      skipLoadingOnReload: true,
      loading: () => const _FormSkeleton(),
      error: (_, __) => _ReviewForm(
        bookId: bookId,
        title: title,
        authorName: authorName,
        coverUrl: coverUrl,
        existing: null,
      ),
      data: (review) => _ReviewForm(
        bookId: bookId,
        title: title,
        authorName: authorName,
        coverUrl: coverUrl,
        existing: review,
      ),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({
    required this.bookId,
    required this.title,
    required this.authorName,
    required this.coverUrl,
    required this.existing,
  });

  final String bookId;
  final String title;
  final String authorName;
  final String? coverUrl;
  final MyReview? existing;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  late final TextEditingController _comment;
  late int _rating;
  late final int _initialRating;
  late final String _initialComment;
  bool _done = false;

  bool get _isEdit => widget.existing != null;

  bool get _dirty =>
      _rating != _initialRating || _comment.text.trim() != _initialComment;

  @override
  void initState() {
    super.initState();
    _initialRating = widget.existing?.rating ?? 0;
    _initialComment = widget.existing?.comment.trim() ?? '';
    _rating = _initialRating;
    _comment = TextEditingController(text: _initialComment)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(reviewSubmitControllerProvider(widget.bookId).notifier)
        .submit(rating: _rating, comment: _comment.text);
    if (!ok || !mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _isEdit ? 'Your review was updated.' : 'Thanks! Your review is live.',
        ),
      ),
    );
    _done = true;
    context.pop(true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text(
          'Your rating and comment will be removed from this book.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: ctx.palette.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(reviewSubmitControllerProvider(widget.bookId).notifier)
        .delete();
    if (!ok || !mounted) return;

    messenger.showSnackBar(const SnackBar(content: Text('Review removed.')));
    _done = true;
    context.pop(true);
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your review has not been saved yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Discard', style: TextStyle(color: ctx.palette.error)),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      _done = true;
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final theme = Theme.of(context);
    final submit = ref.watch(reviewSubmitControllerProvider(widget.bookId));
    final canSubmit = _rating > 0 && _dirty && !submit.isSaving;
    final bookTitle = widget.title.isEmpty ? 'this book' : widget.title;

    return PopScope(
      canPop: _done || (!_dirty && !submit.isSaving),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || submit.isSaving) return;
        _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            _Header(isEdit: _isEdit),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.pagePadding,
                    AppDimens.xl,
                    AppDimens.pagePadding,
                    AppDimens.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BookCard(
                        title: bookTitle,
                        authorName: widget.authorName,
                        coverUrl: widget.coverUrl,
                      ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04),
                      const SizedBox(height: AppDimens.xxl),
                      Center(
                        child: Text(
                          'HOW WAS IT?',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: c.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.lg),
                      StarRatingInput(
                            rating: _rating,
                            onChanged: (v) => setState(() => _rating = v),
                          )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 350.ms)
                          .slideY(begin: 0.04),
                      const SizedBox(height: AppDimens.xxl),
                      Text(
                        'YOUR REVIEW (OPTIONAL)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: c.accent,
                        ),
                      ),
                      const SizedBox(height: AppDimens.sm),
                      TextField(
                            controller: _comment,
                            minLines: 5,
                            maxLines: 8,
                            maxLength: 500,
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              hintText: 'What stayed with you? The story, the writing, the pacing…',
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 350.ms)
                          .slideY(begin: 0.04),
                      if (submit.error != null) ...[
                        const SizedBox(height: AppDimens.md),
                        _ErrorBanner(message: submit.error!),
                      ],
                      if (_isEdit) ...[
                        const SizedBox(height: AppDimens.lg),
                        Center(
                          child: TextButton.icon(
                            onPressed: submit.isSaving ? null : _delete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: c.error,
                            ),
                            label: Text(
                              'Delete my review',
                              style: TextStyle(color: c.error),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                AppDimens.pagePadding,
                AppDimens.md,
                AppDimens.pagePadding,
                AppDimens.md + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: canSubmit ? _submit : null,
                  child: submit.isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(_isEdit ? 'Update review' : 'Submit review'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isEdit});

  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimens.sm,
        MediaQuery.of(context).padding.top + AppDimens.sm,
        AppDimens.pagePadding,
        AppDimens.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, Color.lerp(c.primary, Colors.black, 0.35)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.onPrimary,
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppDimens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'YOUR REVIEW' : 'SHARE YOUR THOUGHTS',
                  style: theme.textTheme.labelMedium?.copyWith(color: c.accent),
                ),
                const SizedBox(height: 4),
                Text(
                  isEdit ? 'Edit your review' : 'Write a review',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.title,
    required this.authorName,
    required this.coverUrl,
  });

  final String title;
  final String authorName;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final theme = Theme.of(context);
    final url = coverUrl;

    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 56,
              height: 84,
              child: (url == null || url.isEmpty)
                  ? _coverPlaceholder(c)
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _coverPlaceholder(c),
                      placeholder: (_, __) => ColoredBox(color: c.border),
                    ),
            ),
          ),
          const SizedBox(width: AppDimens.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (authorName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder(dynamic c) => ColoredBox(
    color: c.border as Color,
    child: Icon(Icons.menu_book_rounded, color: c.textSecondary as Color),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: c.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusInput),
        border: Border.all(color: c.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: c.error, size: 20),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(message, style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );
  }
}

class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    Widget box(double h, {double? w}) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: c.border,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          const _Header(isEdit: false),
          Padding(
            padding: const EdgeInsets.all(AppDimens.pagePadding),
            child: Shimmer.fromColors(
              baseColor: c.border,
              highlightColor: c.surface,
              child: Column(
                children: [
                  box(108),
                  const SizedBox(height: AppDimens.xxl),
                  box(46, w: 260),
                  const SizedBox(height: AppDimens.xxl),
                  box(150),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
