import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BookListSkeleton extends StatelessWidget {
  const BookListSkeleton({super.key, required this.isGrid});

  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    final pad = AppDimens.pagePadding;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(pad, 4, pad, 8),
      sliver: isGrid
          ? SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 22,
                childAspectRatio: 0.52,
              ),
              itemCount: 6,
              itemBuilder: (context, _) =>
                  _shimmer(context, _gridItem(context)),
            )
          : SliverList.separated(
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, _) => _shimmer(context, _rowItem(context)),
            ),
    );
  }

  Widget _shimmer(BuildContext context, Widget child) => Shimmer.fromColors(
    baseColor: context.border,
    highlightColor: context.surface,
    child: child,
  );

  Widget _block(double? w, double h, {double r = 6}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
    ),
  );

  Widget _gridItem(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AspectRatio(
        aspectRatio: 2 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      const SizedBox(height: 10),
      _block(double.infinity, 14),
      const SizedBox(height: 6),
      _block(80, 12),
    ],
  );

  Widget _rowItem(BuildContext context) => Row(
    children: [
      _block(88, 132, r: 10),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _block(60, 10),
            const SizedBox(height: 10),
            _block(double.infinity, 16),
            const SizedBox(height: 8),
            _block(100, 12),
            const SizedBox(height: 40),
            _block(70, 14),
          ],
        ),
      ),
    ],
  );
}
