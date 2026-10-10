import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Stable hash (String.hashCode is not guaranteed stable across runs).
int stableSeed(String s) {
  var h = 7;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

/// The outer side of a book: cover photo cropped to a strip + 3D-ish shading.
class BookSpine extends StatelessWidget {
  const BookSpine({
    super.key,
    required this.title,
    required this.coverUrl,
    required this.seed,
    required this.width,
    required this.height,
  });

  final String title;
  final String? coverUrl;
  final int seed;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = HSLColor.fromAHSL(
      1,
      (seed % 360).toDouble(),
      0.30,
      dark ? 0.26 : 0.32,
    ).toColor();
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;
    const band = ColoredBox(color: Color(0xCCD4A95A));

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: base),
            if (hasCover)
              CachedNetworkImage(
                imageUrl: coverUrl!,
                fit: BoxFit.cover, // centre strip of the cover
                alignment: Alignment.center,
                width: width,
                height: height,
                fadeInDuration: const Duration(milliseconds: 180),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              )
            else
              Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                ),
              ),
            // spine curvature shading
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: .45),
                    Colors.transparent,
                    Colors.white.withValues(alpha: .12),
                    Colors.transparent,
                    Colors.black.withValues(alpha: .5),
                  ],
                  stops: const [0, .2, .38, .7, 1],
                ),
              ),
            ),
            // binding bands
            Positioned(
              left: 0,
              right: 0,
              top: height * .07,
              height: 2,
              child: band,
            ),
            Positioned(
              left: 0,
              right: 0,
              top: height * .07 + 5,
              height: 1,
              child: band,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: height * .07,
              height: 2,
              child: band,
            ),
          ],
        ),
      ),
    );
  }
}
