import 'package:flutter/material.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/shared/models/user_profile.dart';

/// [stats] is null while loading or if the request failed (shows a dash).
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.stats});

  final ProfileStats? stats;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    String v(int? n) => n == null ? '–' : '$n';

    Widget divider() =>
        Container(width: 1, height: 36, color: c.accent.withValues(alpha: 0.5));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          _StatCell(value: v(stats?.orders), label: 'ORDERS'),
          divider(),
          _StatCell(value: v(stats?.wishlist), label: 'WISHLIST'),
          divider(),
          _StatCell(value: v(stats?.reviews), label: 'REVIEWS'),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: text.headlineSmall?.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.labelMedium?.copyWith(
              color: c.textSecondary,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
