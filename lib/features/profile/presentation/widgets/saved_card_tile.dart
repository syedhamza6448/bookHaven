import 'package:flutter/material.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/shared/models/saved_card.dart';

class SavedCardTile extends StatelessWidget {
  const SavedCardTile({
    super.key,
    required this.card,
    required this.busy,
    required this.onSetDefault,
    required this.onDelete,
  });

  final SavedCard card;
  final bool busy;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    const onCard = AppColors.onPrimary;
    const gold = AppColors.darkAccent;
    final expired = card.isExpired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 176,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: expired
                  ? const [Color(0xFF4A4A46), Color(0xFF2E2E2B)]
                  : const [Color(0xFF2A5247), Color(0xFF14282A)],
            ),
            border: card.isDefault ? Border.all(color: gold, width: 1.2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 26,
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const Spacer(),
                  if (card.isDefault)
                    const _Badge(label: 'DEFAULT', filled: true),
                  if (expired) ...[
                    const SizedBox(width: 6),
                    const _Badge(label: 'EXPIRED', filled: false),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                card.maskedNumber,
                style: t.titleMedium?.copyWith(
                  color: onCard,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _Field(
                      label: 'CARD HOLDER',
                      value: card.holderName.toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Field(label: 'EXPIRES', value: card.expiryLabel),
                  const SizedBox(width: 16),
                  Text(
                    card.brand.label.toUpperCase(),
                    style: t.labelMedium?.copyWith(
                      color: gold,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (!card.isDefault && !expired)
              TextButton.icon(
                onPressed: busy ? null : onSetDefault,
                icon: const Icon(Icons.bookmark_border_rounded, size: 18),
                label: const Text('Set as default'),
              ),
            const Spacer(),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            TextButton.icon(
              onPressed: busy ? null : onDelete,
              style: TextButton.styleFrom(foregroundColor: c.error),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Remove'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: t.labelSmall?.copyWith(
            color: AppColors.onPrimary.withValues(alpha: 0.6),
            letterSpacing: 1.2,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodyMedium?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.filled});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final color = filled ? AppColors.darkAccent : AppColors.darkError;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: filled ? null : Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: filled ? const Color(0xFF1C1A17) : color,
        ),
      ),
    );
  }
}
