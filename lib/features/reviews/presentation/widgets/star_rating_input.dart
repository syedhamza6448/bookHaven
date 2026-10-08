import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/theme/app_palette.dart';

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 46,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  static const labels = <int, String>{
    0: 'Tap a star to rate',
    1: 'Not for me',
    2: 'It was okay',
    3: 'Good read',
    4: 'Really liked it',
    5: 'Loved it',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < rating;
            return Semantics(
              button: true,
              label: '${i + 1} star${i == 0 ? '' : 's'}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(i + 1);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedScale(
                    scale: filled ? 1.0 : 0.88,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: size,
                      color: filled
                          ? AppColors.star
                          : c.textSecondary.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            labels[rating] ?? '',
            key: ValueKey(rating),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: rating == 0 ? c.textSecondary : c.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
