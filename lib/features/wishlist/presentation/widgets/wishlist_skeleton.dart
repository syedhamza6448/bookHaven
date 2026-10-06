import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bookhaven/core/theme/app_palette.dart';

class WishlistSkeleton extends StatelessWidget {
  const WishlistSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    Widget box() => Expanded(
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );

    Widget row() => Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(children: [box(), const SizedBox(width: 16), box()]),
          ),
          const SizedBox(height: 4),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );

    return Shimmer.fromColors(
      baseColor: c.border,
      highlightColor: c.surface,
      child: Column(children: [row(), row()]),
    );
  }
}
