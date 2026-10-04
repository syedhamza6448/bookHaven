import 'package:flutter/material.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/shared/models/address.dart';

class AddressTile extends StatelessWidget {
  const AddressTile({
    super.key,
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimens.lg),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? c.primary : c.textSecondary,
                size: 22,
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label,
                          style: text.titleMedium?.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: AppDimens.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: text.labelSmall?.copyWith(color: c.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${address.fullName} · ${address.phone}',
                      style: text.bodyMedium?.copyWith(color: c.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address.oneLine,
                      style: text.bodySmall?.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
