import 'package:flutter/material.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';

class CheckoutSection extends StatelessWidget {
  const CheckoutSection({
    super.key,
    required this.number,
    required this.title,
    required this.child,
  });

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.accent),
              ),
              child: Text(
                '$number',
                style: text.labelMedium?.copyWith(color: c.accent),
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            Text(
              title.toUpperCase(),
              style: text.labelMedium?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.sm),
        Container(height: 1, color: c.accent.withValues(alpha: 0.4)),
        const SizedBox(height: AppDimens.lg),
        child,
      ],
    );
  }
}
