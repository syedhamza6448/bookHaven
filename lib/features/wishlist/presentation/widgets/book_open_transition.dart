import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:bookhaven/core/theme/app_palette.dart';

import 'book_spine.dart';

const double _persp = 0.0006;

/// Pulls the book off the shelf, turns it spine -> cover, opens the cover,
/// calls [onCovered] (push your details route there) and fades away.
Future<void> playBookOpenTransition({
  required BuildContext context,
  required String title,
  required String? coverUrl,
  required int seed,
  required Size spineSize,
  required Offset startCenter,
  required double startLean,
  required VoidCallback onCovered,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _BookOpenOverlay(
      title: title,
      coverUrl: coverUrl,
      seed: seed,
      spineSize: spineSize,
      startCenter: startCenter,
      startLean: startLean,
      onCovered: onCovered,
      onDone: () {
        entry.remove();
        entry.dispose();
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _BookOpenOverlay extends StatefulWidget {
  const _BookOpenOverlay({
    required this.title,
    required this.coverUrl,
    required this.seed,
    required this.spineSize,
    required this.startCenter,
    required this.startLean,
    required this.onCovered,
    required this.onDone,
  });

  final String title;
  final String? coverUrl;
  final int seed;
  final Size spineSize;
  final Offset startCenter;
  final double startLean;
  final VoidCallback onCovered;
  final VoidCallback onDone;

  @override
  State<_BookOpenOverlay> createState() => _BookOpenOverlayState();
}

class _BookOpenOverlayState extends State<_BookOpenOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    _c =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1150),
          )
          ..addListener(() {
            if (!_covered && _c.value >= 0.74) {
              _covered = true;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => widget.onCovered(),
              );
            }
          })
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) widget.onDone();
          })
          ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _seg(double p, double a, double b) =>
      ((p - a) / (b - a)).clamp(0.0, 1.0);
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final paper = context.palette.bg;
    final coverW = math.min(size.width * 0.58, 230.0);
    final coverH = coverW * 1.5;
    final spineW = widget.spineSize.width;
    final spineH = widget.spineSize.height;
    final depth =
        spineW *
        coverH /
        spineH; // book thickness (same proportions as the shelf spine)
    final scale0 = spineH / (coverH + spineH * _persp * coverW / 2);
    final fillScale = math.max(size.width / coverW, size.height / coverH) * 1.1;

    return AbsorbPointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final p = _c.value;
          final a1 = Curves.easeInOutCubic.transform(
            _seg(p, 0.0, 0.42),
          ); // pull out + turn
          final a2 = Curves.easeInOutCubic.transform(
            _seg(p, 0.38, 0.80),
          ); // open cover
          final fade = _seg(p, 0.86, 1.0);

          final yaw = (1 - a1) * math.pi / 2;
          final psi = a2 * math.pi * 0.93;
          final lean = widget.startLean * (1 - a1);
          final scale = _lerp(scale0, 1, a1) * _lerp(1, fillScale, a2);
          final wCur = 1 - _persp * scale * (coverW / 2) * math.sin(yaw);

          final visual = Offset.lerp(
            widget.startCenter,
            size.center(Offset.zero),
            a1,
          )!;
          final center =
              visual + Offset(depth / 2 * math.sin(yaw) * scale / wCur, 0);

          final m = Matrix4.identity()
            ..setEntry(3, 2, _persp)
            ..scale(scale, scale, scale)
            ..rotateZ(lean)
            ..rotateY(-yaw);

          return Opacity(
            opacity: 1 - fade,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: .5 * a1),
                  ),
                ),
                Positioned(
                  left: center.dx - coverW / 2,
                  top: center.dy - coverH / 2,
                  width: coverW,
                  height: coverH,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: m,
                    child: _book(coverW, coverH, depth, yaw, psi, paper),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _book(
    double w,
    double h,
    double depth,
    double yaw,
    double psi,
    Color paper,
  ) {
    final hasCover = widget.coverUrl != null && widget.coverUrl!.isNotEmpty;
    final base = HSLColor.fromAHSL(
      1,
      (widget.seed % 360).toDouble(),
      .30,
      .30,
    ).toColor();

    final front = ClipRRect(
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: base),
          if (hasCover)
            CachedNetworkImage(imageUrl: widget.coverUrl!, fit: BoxFit.cover)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: .35),
                  Colors.transparent,
                ],
                stops: const [0, .08],
              ),
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // inside page
          Positioned.fill(child: ColoredBox(color: paper)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: .12),
                    Colors.transparent,
                  ],
                  stops: const [0, .15],
                ),
              ),
            ),
          ),
          // cover, hinged on its left edge
          Positioned.fill(
            child: Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()..rotateY(psi),
              child: psi < math.pi / 2
                  ? front
                  : ColoredBox(color: Color.lerp(paper, Colors.black, .06)!),
            ),
          ),
          // spine, folded back from the left edge
          if (yaw > 0.01)
            Positioned(
              left: -depth,
              top: 0,
              width: depth,
              height: h,
              child: Transform(
                alignment: Alignment.centerRight,
                transform: Matrix4.identity()..rotateY(math.pi / 2),
                child: BookSpine(
                  title: widget.title,
                  coverUrl: widget.coverUrl,
                  seed: widget.seed,
                  width: depth,
                  height: h,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
