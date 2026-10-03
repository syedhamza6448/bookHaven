import 'package:flutter/material.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimens.radiusInput);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        AppDimens.lg,
        AppDimens.pagePadding,
        0,
      ),
      child: Material(
        color: context.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: context.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: AppDimens.lg),
                Icon(Icons.search_rounded, color: context.textSecondary),
                const SizedBox(width: AppDimens.md),
                Text(
                  'Search title, author or genre',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
