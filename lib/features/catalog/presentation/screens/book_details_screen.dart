import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/cart/data/cart_repository.dart';
import 'package:bookhaven/features/catalog/data/book_details_repository.dart';
import 'package:bookhaven/features/catalog/presentation/providers/book_details_providers.dart';
import 'package:bookhaven/features/catalog/presentation/widgets/book_reviews_section.dart';
import 'package:bookhaven/features/catalog/presentation/widgets/related_books_row.dart';
import 'package:bookhaven/features/wishlist/data/wishlist_repository.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class BookDetailsScreen extends ConsumerStatefulWidget {
  const BookDetailsScreen({super.key, required this.bookId, this.heroTag});

  final String bookId;
  final String? heroTag;

  @override
  ConsumerState<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends ConsumerState<BookDetailsScreen> {
  int _qty = 1;
  bool _adding = false;
  bool _expanded = false;

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggleWishlist() async {
    try {
      final now = await ref
          .read(wishlistRepositoryProvider)
          .toggle(widget.bookId);
      ref.invalidate(isWishlistedProvider(widget.bookId));
      _snack(now ? 'Saved to your wishlist' : 'Removed from your wishlist');
    } catch (_) {
      _snack('Could not update wishlist. Try again.');
    }
  }

  Future<void> _addToCart(Book book) async {
    setState(() => _adding = true);
    try {
      final total = await ref
          .read(cartRepositoryProvider)
          .addItem(bookId: widget.bookId, quantity: _qty, stock: book.stock);
      if (!mounted) return;
      setState(() => _qty = 1);
      _snack('Added to your cart ($total in cart)');
    } catch (_) {
      if (mounted) _snack('Could not add to cart. Try again.');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final async = ref.watch(bookDetailsProvider(widget.bookId));

    return Scaffold(
      backgroundColor: c.bg,
      body: async.when(
        loading: () => _Skeleton(onBack: () => context.pop()),
        error: (e, _) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load this book.',
                        style: TextStyle(color: c.textSecondary),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(bookDetailsProvider(widget.bookId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (details) => _buildContent(context, details),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (d) => _PurchaseBar(
          book: d.book,
          qty: _qty,
          adding: _adding,
          onMinus: () => setState(() => _qty = (_qty - 1).clamp(1, 99)),
          onPlus: () => setState(() {
            if (_qty < d.book.stock) {
              _qty++;
            } else {
              _snack('Only ${d.book.stock} copies available');
            }
          }),
          onAdd: () => _addToCart(d.book),
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildContent(BuildContext context, BookDetails details) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final book = details.book;
    final author = book.authorName ?? 'Unknown author';
    final genre = book.genreName ?? '';
    final wished =
        ref.watch(isWishlistedProvider(widget.bookId)).value ?? false;
    final desc = (book.description ?? '').trim();

    final availability = !book.inStock
        ? 'Out of stock'
        : (book.stock <= 5 ? 'Only ${book.stock} left' : 'In stock');

    return RefreshIndicator(
      color: c.accent,
      onRefresh: () async {
        ref.invalidate(bookDetailsProvider(widget.bookId));
        ref.invalidate(bookReviewsProvider(widget.bookId));
        ref.invalidate(isWishlistedProvider(widget.bookId));
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppDimens.sm,
              bottom: AppDimens.xxl,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.lightPrimary, Color(0xFF12261F)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
                  child: Row(
                    children: [
                      _RoundIcon(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.pop(),
                      ),
                      const Spacer(),
                      _RoundIcon(
                        icon: wished
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: AppColors.darkAccent,
                        onTap: _toggleWishlist,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.md),
                Hero(
                  tag: widget.heroTag ?? 'details-${book.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: book.coverUrl ?? '',
                        width: 170,
                        height: 250,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                          width: 170,
                          height: 250,
                          color: c.border,
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 48,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadding,
              AppDimens.xl,
              AppDimens.pagePadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (genre.isNotEmpty)
                  Text(
                    genre.toUpperCase(),
                    style: text.labelMedium?.copyWith(color: c.accent),
                  ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  book.title,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                GestureDetector(
                  onTap: details.authorId == null
                      ? null
                      : () => context.push(
                          AppRoutes.bookListPath(
                            title: author,
                            authorId: details.authorId,
                          ),
                        ),
                  child: Text(
                    'by $author',
                    style: text.bodyLarge?.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.md),
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      final v = book.ratingAvg.toDouble();
                      final icon = v >= i + 1
                          ? Icons.star_rounded
                          : (v >= i + 0.5
                                ? Icons.star_half_rounded
                                : Icons.star_border_rounded);
                      return Icon(icon, size: 20, color: c.accent);
                    }),
                    const SizedBox(width: AppDimens.sm),
                    Text(
                      book.ratingCount == 0
                          ? 'No ratings yet'
                          : '${book.ratingAvg.toStringAsFixed(1)} (${book.ratingCount})',
                      style: text.bodyMedium?.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.lg),
                Container(height: 1, color: c.accent.withValues(alpha: 0.5)),
                const SizedBox(height: AppDimens.lg),
                Row(
                  children: [
                    _Fact(label: 'GENRE', value: genre.isEmpty ? '-' : genre),
                    _FactDivider(color: c.border),
                    _Fact(label: 'AVAILABILITY', value: availability),
                    _FactDivider(color: c.border),
                    _Fact(
                      label: 'RATING',
                      value: book.ratingCount == 0
                          ? '-'
                          : book.ratingAvg.toStringAsFixed(1),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.lg),
                Container(height: 1, color: c.accent.withValues(alpha: 0.5)),
                const SizedBox(height: AppDimens.xl),
                Text(
                  'ABOUT THIS BOOK',
                  style: text.labelMedium?.copyWith(color: c.accent),
                ),
                const SizedBox(height: AppDimens.md),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  alignment: Alignment.topCenter,
                  child: Text(
                    desc.isEmpty ? 'No description available.' : desc,
                    maxLines: _expanded ? null : 5,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: c.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
                if (desc.length > 220)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => setState(() => _expanded = !_expanded),
                      child: Text(_expanded ? 'Read less' : 'Read more'),
                    ),
                  ),
                const SizedBox(height: AppDimens.xl),
                BookReviewsSection(bookId: widget.bookId),
                const SizedBox(height: AppDimens.xl),
              ],
            ),
          ),
          RelatedBooksRow(
            bookId: widget.bookId,
            genreId: details.genreId,
            genreName: genre,
          ),
          const SizedBox(height: AppDimens.xxl),
        ].animate(interval: 60.ms).fadeIn(duration: 350.ms).slideY(begin: 0.03, end: 0),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              icon,
              key: ValueKey(icon),
              size: 24,
              color: color ?? const Color(0xFFF6F1E7),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: c.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall?.copyWith(color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _FactDivider extends StatelessWidget {
  const _FactDivider({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: color);
}

class _PurchaseBar extends StatelessWidget {
  const _PurchaseBar({
    required this.book,
    required this.qty,
    required this.adding,
    required this.onMinus,
    required this.onPlus,
    required this.onAdd,
  });

  final Book book;
  final int qty;
  final bool adding;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        AppDimens.md,
        AppDimens.pagePadding,
        MediaQuery.of(context).padding.bottom + AppDimens.md,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                formatPrice(book.price),
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              if (book.hasDiscount && book.originalPrice != null) ...[
                const SizedBox(width: AppDimens.sm),
                Text(
                  formatPrice(book.originalPrice!),
                  style: text.bodyMedium?.copyWith(
                    color: c.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-${book.discountPercent}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (book.inStock)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: qty > 1 ? onMinus : null,
                        icon: const Icon(Icons.remove_rounded, size: 20),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$qty',
                          textAlign: TextAlign.center,
                          style: text.titleSmall?.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onPlus,
                        icon: const Icon(Icons.add_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.md),
          SizedBox(
            width: double.infinity,
            height: AppDimens.buttonHeight,
            child: FilledButton.icon(
              onPressed: (!book.inStock || adding) ? null : onAdd,
              icon: adding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFF6F1E7),
                      ),
                    )
                  : const Icon(Icons.shopping_bag_outlined),
              label: Text(book.inStock ? 'Add to cart' : 'Out of stock'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    Widget box(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c.border,
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return SafeArea(
      child: Shimmer.fromColors(
        baseColor: c.border,
        highlightColor: c.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: box(170, 250)),
              const SizedBox(height: AppDimens.xl),
              box(80, 12),
              const SizedBox(height: AppDimens.md),
              box(260, 30),
              const SizedBox(height: AppDimens.md),
              box(140, 16),
              const SizedBox(height: AppDimens.xl),
              box(double.infinity, 14),
              const SizedBox(height: AppDimens.sm),
              box(double.infinity, 14),
              const SizedBox(height: AppDimens.sm),
              box(200, 14),
            ],
          ),
        ),
      ),
    );
  }
}
