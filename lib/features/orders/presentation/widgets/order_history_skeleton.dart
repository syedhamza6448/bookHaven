import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';

class OrderHistorySkeleton extends StatelessWidget {
  const OrderHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Shimmer.fromColors(
      baseColor: c.border,
      highlightColor: c.surface,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.pagePadding),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.lg),
        itemBuilder: (_, __) => Container(
          height: 168,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          ),
        ),
      ),
    );
  }
}
