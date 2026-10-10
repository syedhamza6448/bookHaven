import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:bookhaven/shared/models/book.dart';

import 'book_open_transition.dart';
import 'book_spine.dart';

const double _kMaxLean = 0.46; // ~26 degrees
const double _kPlankH = 16;
const double _kWallPad = 2;
const double _kRestPad = 14;
const double _kGap = 2;
const int kBooksPerShelf = 6;

/// If the books fall the wrong way on your phone, change this to -1.
const double _kSensorDirection = 1;

class WishlistShelfRow extends StatefulWidget {
  const WishlistShelfRow({
    super.key,
    required this.books,
    required this.onOpen,
    required this.onRemove,
    required this.onMoveToCart,
    this.showPlank = true,
  });

  /// Place this row full-width (outside page padding) so the phone edges
  /// act as the walls.
  final List<Book> books;

  /// Called once the book-opening animation has covered the screen.
  final void Function(Book book, String heroTag) onOpen;
  final void Function(Book book) onRemove;
  final void Function(Book book) onMoveToCart;
  final bool showPlank;

  @override
  State<WishlistShelfRow> createState() => _WishlistShelfRowState();
}

class _WishlistShelfRowState extends State<WishlistShelfRow>
    with SingleTickerProviderStateMixin {
  final _tilt = ValueNotifier<double>(0);
  final _keys = <String, GlobalKey>{};
  final _leans = <String, double>{};
  late final Ticker _ticker;
  StreamSubscription<AccelerometerEvent>? _sub;
  Duration _last = Duration.zero;
  double _target = 0, _pos = 0, _vel = 0;
  String? _pulledId;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only listen while this tab is actually visible (saves battery).
    if (TickerMode.of(context)) {
      _listen();
    } else {
      _stop();
    }
  }

  void _listen() {
    _sub ??=
        accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
            .listen((e) {
              var t = (_kSensorDirection * -e.x / 4.5).clamp(
                -1.0,
                1.0,
              ); // full lean at ~27 deg
              const dead = 0.12;
              t = t.abs() < dead ? 0 : t.sign * (t.abs() - dead) / (1 - dead);
              _target = t;
            }, onError: (_) => _target = 0);
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    _target = 0;
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (dt == 0) return;
    const k = 70.0, c = 9.5; // spring + damping (slightly bouncy)
    _vel += (k * (_target - _pos) - c * _vel) * dt;
    _pos += _vel * dt;
    if ((_pos - _tilt.value).abs() > 0.0004) _tilt.value = _pos;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    _tilt.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- layout

  _Dims _dims(double width) {
    final n = widget.books.length;
    var w = <double>[];
    final h = <double>[];
    for (final b in widget.books) {
      final s = stableSeed(b.id);
      w.add(24 + (s % 9).toDouble());
      h.add(150 + ((s ~/ 7) % 36).toDouble());
    }
    final hMax = h.reduce(math.max);
    // make sure the fully-leaning pile still fits in the row
    final avail = width - 2 * _kWallPad - hMax * math.sin(_kMaxLean);
    final needed = w.fold<double>(0, (a, b) => a + b) / math.cos(_kMaxLean);
    if (needed > avail && n > 0) {
      final f = avail / needed;
      w = [for (final x in w) x * f];
    }
    return _Dims(w, h, hMax + _kPlankH + 14);
  }

  List<_Placed> _place(_Dims d, double width, double t) {
    final n = d.w.length;
    final a = t.abs().clamp(0.0, 1.1);
    final side = t >= 0 ? 1 : -1;
    final theta = _kMaxLean * a;
    final sinT = math.sin(theta), cosT = math.cos(theta);

    final restLeft = List<double>.filled(n, 0);
    var x = _kRestPad;
    for (var i = 0; i < n; i++) {
      restLeft[i] = x;
      x += d.w[i] + _kGap;
    }

    // fully-fallen pivot positions (pivot = bottom corner on the downhill side)
    final packed = List<double>.filled(n, 0);
    if (side == 1) {
      final wall = width - _kWallPad;
      packed[n - 1] = wall - d.h[n - 1] * sinT;
      for (var i = n - 2; i >= 0; i--) {
        packed[i] = packed[i + 1] - d.w[i + 1] / cosT;
      }
      var over = 0.0;
      for (var i = 0; i < n; i++) {
        over = math.max(over, packed[i] + d.h[i] * sinT - wall);
      }
      if (over > 0) {
        for (var i = 0; i < n; i++) {
          packed[i] -= over;
        }
      }
    } else {
      const wall = _kWallPad;
      packed[0] = wall + d.h[0] * sinT;
      for (var i = 1; i < n; i++) {
        packed[i] = packed[i - 1] + d.w[i - 1] / cosT;
      }
      var under = 0.0;
      for (var i = 0; i < n; i++) {
        under = math.max(under, wall - (packed[i] - d.h[i] * sinT));
      }
      if (under > 0) {
        for (var i = 0; i < n; i++) {
          packed[i] += under;
        }
      }
    }

    return List.generate(n, (i) {
      final rank = side == 1
          ? (n - 1 - i)
          : i; // books nearest the wall move first
      final frac = n > 1 ? rank / (n - 1) : 0.0;
      final s = Curves.easeOutCubic.transform(
        ((a * 2.4) - frac * 0.9).clamp(0.0, 1.0),
      );
      final restPivot = side == 1 ? restLeft[i] + d.w[i] : restLeft[i];
      final pivot = restPivot + (packed[i] - restPivot) * s;
      return _Placed(
        left: side == 1 ? pivot - d.w[i] : pivot,
        angle: side * theta,
        alignment: side == 1 ? Alignment.bottomRight : Alignment.bottomLeft,
      );
    });
  }

  // --------------------------------------------------------------- actions

  Future<void> _open(Book book) async {
    if (_pulledId != null) return;
    final onOpen = widget.onOpen;
    final tag = 'wishlist-${book.id}';
    final box =
        _keys[book.id]?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      onOpen(book, tag);
      return;
    }
    final center = box.localToGlobal(box.size.center(Offset.zero));
    setState(() => _pulledId = book.id);
    await playBookOpenTransition(
      context: context,
      title: book.title,
      coverUrl: book.coverUrl,
      seed: stableSeed(book.id),
      spineSize: box.size,
      startCenter: center,
      startLean: _leans[book.id] ?? 0,
      onCovered: () => onOpen(book, tag),
    );
    if (mounted) setState(() => _pulledId = null);
  }

  void _showActions(Book book) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Move to cart'),
              onTap: () {
                Navigator.pop(sheetCtx);
                widget.onMoveToCart(book);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Remove from wishlist'),
              onTap: () {
                Navigator.pop(sheetCtx);
                widget.onRemove(book);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    if (widget.books.isEmpty) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final d = _dims(width);
        return SizedBox(
          width: width,
          height: d.rowHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.showPlank)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _kPlankH,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: dark
                            ? const [Color(0xFF3A2E24), Color(0xFF241B14)]
                            : const [Color(0xFFA27B52), Color(0xFF7C5A38)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 1.5,
                        color: Colors.white.withValues(alpha: .22),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: ValueListenableBuilder<double>(
                  valueListenable: _tilt,
                  builder: (context, t, _) {
                    final placed = _place(d, width, t);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < widget.books.length; i++)
                          Positioned(
                            left: placed[i].left,
                            bottom: _kPlankH - 1,
                            child: Transform.rotate(
                              angle: placed[i].angle,
                              alignment: placed[i].alignment,
                              child: _tile(
                                widget.books[i],
                                d.w[i],
                                d.h[i],
                                placed[i].angle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(Book book, double w, double h, double angle) {
    _leans[book.id] = angle;
    final key = _keys.putIfAbsent(book.id, () => GlobalKey());
    return Opacity(
      opacity: _pulledId == book.id ? 0 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(book),
        onLongPress: () => _showActions(book),
        child: DecoratedBox(
          key: key,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .28),
                blurRadius: 6,
                offset: const Offset(2, 1),
              ),
            ],
          ),
          child: BookSpine(
            title: book.title,
            coverUrl: book.coverUrl,
            seed: stableSeed(book.id),
            width: w,
            height: h,
          ),
        ),
      ),
    );
  }
}

class _Dims {
  _Dims(this.w, this.h, this.rowHeight);
  final List<double> w;
  final List<double> h;
  final double rowHeight;
}

class _Placed {
  _Placed({required this.left, required this.angle, required this.alignment});
  final double left;
  final double angle;
  final Alignment alignment;
}
