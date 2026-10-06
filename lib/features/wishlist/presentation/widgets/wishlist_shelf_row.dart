import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/shared/models/book.dart';

class WishlistShelfRow extends StatelessWidget {
  const WishlistShelfRow({
    super.key,
    required this.books,
    required this.onOpen,
    required this.onRemove,
    required this.onMoveToCart,
  });

  /// 1 or 2 books.
  final List<Book> books;
  final void Function(Book book, String heroTag) onOpen;
  final void Function(Book book) onRemove;
  final Future<void> Function(Book book) onMoveToCart;

  static String heroTagFor(Book b) => 'wishlist-${b.id}';

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    const gap = 16.0;

    Widget slot(int i, Widget Function(Book b) builder) {
      return Expanded(
        child: i < books.length ? builder(books[i]) : const SizedBox.shrink(),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.xxl),
      child: Column(
        children: [
          // Covers standing on the shelf
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                slot(
                  0,
                  (b) => _Cover(
                    book: b,
                    heroTag: heroTagFor(b),
                    onTap: () => onOpen(b, heroTagFor(b)),
                    onRemove: () => onRemove(b),
                  ),
                ),
                const SizedBox(width: gap),
                slot(
                  1,
                  (b) => _Cover(
                    book: b,
                    heroTag: heroTagFor(b),
                    onTap: () => onOpen(b, heroTagFor(b)),
                    onRemove: () => onRemove(b),
                  ),
                ),
              ],
            ),
          ),
          // The plank
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.border, Color.lerp(c.border, Colors.black, 0.2)!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.md),
          // Title, price, action
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                slot(
                  0,
                  (b) => _Details(
                    book: b,
                    onOpen: () => onOpen(b, heroTagFor(b)),
                    onMoveToCart: () => onMoveToCart(b),
                  ),
                ),
                const SizedBox(width: gap),
                slot(
                  1,
                  (b) => _Details(
                    book: b,
                    onOpen: () => onOpen(b, heroTagFor(b)),
                    onMoveToCart: () => onMoveToCart(b),
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

class _Cover extends StatelessWidget {
  const _Cover({
    required this.book,
    required this.heroTag,
    required this.onTap,
    required this.onRemove,
  });

  final Book book;
  final String heroTag;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final url = book.coverUrl ?? '';

    Widget fallback() => Container(
      color: c.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppDimens.md),
      child: Text(
        book.title,
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: c.textSecondary),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Hero(
                tag: heroTag,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: url.isEmpty
                        ? fallback()
                        : CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: c.border),
                            errorWidget: (_, __, ___) => fallback(),
                          ),
                  ),
                ),
              ),
            ),
            if (book.hasDiscount)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.error,
                    borderRadius: BorderRadius.circular(4),
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
              ),
            // Gold bookmark ribbon: tap to remove
            Positioned(
              top: -2,
              right: 10,
              child: Tooltip(
                message: 'Remove from wishlist',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onRemove,
                  child: ClipPath(
                    clipper: _RibbonClipper(),
                    child: Container(
                      width: 28,
                      height: 42,
                      color: c.accent,
                      alignment: const Alignment(0, -0.35),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: Color(0xFF1C1A17),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - 9)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Details extends StatefulWidget {
  const _Details({
    required this.book,
    required this.onOpen,
    required this.onMoveToCart,
  });

  final Book book;
  final VoidCallback onOpen;
  final Future<void> Function() onMoveToCart;

  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  bool _busy = false;

  Future<void> _move() async {
    setState(() => _busy = true);
    try {
      await widget.onMoveToCart();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final theme = Theme.of(context);
    final book = widget.book;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.onOpen,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                book.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              Row(
                children: [
                  Text(
                    formatPrice(book.price),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (book.hasDiscount && book.originalPrice != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      formatPrice(book.originalPrice!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        SizedBox(
          width: double.infinity,
          child: book.inStock
              ? ElevatedButton(
                  onPressed: _busy ? null : _move,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 16),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Move to cart',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                )
              : OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Out of stock'),
                ),
        ),
      ],
    );
  }
}
