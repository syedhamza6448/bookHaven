import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookhaven/core/theme/app_palette.dart';

class NotchNavItem {
  const NotchNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
}

class NotchNavBar extends StatefulWidget {
  const NotchNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NotchNavItem> items;

  @override
  State<NotchNavBar> createState() => _NotchNavBarState();
}

class _NotchNavBarState extends State<NotchNavBar>
    with SingleTickerProviderStateMixin {
  static const double _barHeight = 64;
  static const double _lift = 26; // room above the bar for the circle
  static const double _hPad = 14; // inner padding of the bar
  static const double _margin = 12; // gap from screen edges
  static const double _circle = 48;

  static const Color _cream = Color(0xFFF6F1E7);
  static const Color _ink = Color(0xFF1C1A17);

  late final AnimationController _ctrl;
  double _from = 0;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    _from = _to = widget.currentIndex.toDouble();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant NotchNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _from = _position;
      _to = widget.currentIndex.toDouble();
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _position =>
      _from + (_to - _from) * Curves.easeOutCubic.transform(_ctrl.value);

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final count = widget.items.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _margin,
        0,
        _margin,
        math.max(bottomInset, 10),
      ),
      child: SizedBox(
        height: _barHeight + _lift,
        child: LayoutBuilder(
          builder: (context, box) {
            final slot = (box.maxWidth - _hPad * 2) / count;

            return AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final pos = _position;
                final cx = _hPad + (pos + 0.5) * slot;
                final pulse = math.sin(math.pi * _ctrl.value);
                final nearest = pos.round().clamp(0, count - 1);
                final nearestItem = widget.items[nearest];

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Bar with the notch cut out
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: _barHeight,
                      child: CustomPaint(
                        painter: _NotchPainter(
                          cx: cx,
                          color: c.primary,
                          shadow: Colors.black.withValues(
                            alpha: c.isDark ? 0.6 : 0.3,
                          ),
                        ),
                      ),
                    ),

                    // Tab icons and labels
                    Positioned(
                      left: _hPad,
                      right: _hPad,
                      bottom: 0,
                      height: _barHeight,
                      child: Row(
                        children: [
                          for (int i = 0; i < count; i++)
                            Expanded(
                              child: _NavSlot(
                                item: widget.items[i],
                                activeness: (1 - (pos - i).abs()).clamp(
                                  0.0,
                                  1.0,
                                ),
                                color: _cream,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onTap(i);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Floating gold circle inside the notch
                    Positioned(
                      left: cx - _circle / 2,
                      top: _lift + 6 - _circle / 2 - 6 * pulse,
                      width: _circle,
                      height: _circle,
                      child: IgnorePointer(
                        child: Transform.scale(
                          scale: 1 + 0.12 * pulse,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: c.accent.withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(
                                    scale: anim,
                                    child: FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    ),
                                  ),
                              child: Badge(
                                key: ValueKey(nearest),
                                isLabelVisible: nearestItem.badge > 0,
                                backgroundColor: _ink,
                                textColor: _cream,
                                label: Text('${nearestItem.badge}'),
                                child: Icon(
                                  nearestItem.activeIcon,
                                  size: 24,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.activeness,
    required this.color,
    required this.onTap,
  });

  final NotchNavItem item;
  final double activeness; // 0 = inactive, 1 = fully active
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = activeness;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inactive icon fades and sinks as the notch arrives
          Opacity(
            opacity: (1 - a * 1.4).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 10 * a),
              child: Badge(
                isLabelVisible: item.badge > 0,
                backgroundColor: const Color(0xFFD4A95A),
                textColor: const Color(0xFF1C1A17),
                label: Text('${item.badge}'),
                child: Icon(
                  item.icon,
                  size: 24,
                  color: color.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
          // Label under the notch
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Opacity(
                opacity: a,
                child: Transform.translate(
                  offset: Offset(0, (1 - a) * 8),
                  child: Text(
                    item.label.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotchPainter extends CustomPainter {
  _NotchPainter({required this.cx, required this.color, required this.shadow});

  final double cx;
  final Color color;
  final Color shadow;

  static const double _depth = 36;
  static const double _halfW = 42;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(26)),
      );

    final notch = Path()
      ..moveTo(cx - _halfW, -1)
      ..cubicTo(cx - 26, -1, cx - 34, _depth, cx, _depth)
      ..cubicTo(cx + 34, _depth, cx + 26, -1, cx + _halfW, -1)
      ..close();

    final path = Path.combine(PathOperation.difference, bar, notch);

    canvas.drawShadow(path, shadow, 10, false);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _NotchPainter old) =>
      old.cx != cx || old.color != color || old.shadow != shadow;
}
