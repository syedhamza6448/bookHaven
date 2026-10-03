import 'package:flutter/material.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';

class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.pagePadding, vertical: AppDimens.lg),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: context.textSecondary),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Text(message,
                  style: textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}