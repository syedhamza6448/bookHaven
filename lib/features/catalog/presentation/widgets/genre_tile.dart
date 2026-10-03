import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/catalog/data/category_repository.dart';
import 'package:flutter/material.dart';

IconData genreIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('fantasy')) return Icons.auto_awesome;
  if (n.contains('sci')) return Icons.rocket_launch_outlined;
  if (n.contains('myster') || n.contains('thrill') || n.contains('crime')) {
    return Icons.manage_search;
  }
  if (n.contains('romance')) return Icons.favorite_border;
  if (n.contains('histor')) return Icons.account_balance_outlined;
  if (n.contains('biograph') || n.contains('memoir'))
    return Icons.person_outline;
  if (n.contains('self') || n.contains('help')) return Icons.self_improvement;
  if (n.contains('business') || n.contains('econom')) return Icons.trending_up;
  if (n.contains('science')) return Icons.science_outlined;
  if (n.contains('horror')) return Icons.nightlight_outlined;
  if (n.contains('poet')) return Icons.edit_outlined;
  if (n.contains('child')) return Icons.child_care;
  if (n.contains('fiction')) return Icons.menu_book_outlined;
  return Icons.auto_stories_outlined;
}

class GenreTile extends StatelessWidget {
  const GenreTile({super.key, required this.genre, required this.onTap});

  final CategoryGenre genre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final deep = Color.lerp(c.primary, Colors.black, 0.3)!;
    final radius = BorderRadius.circular(AppDimens.radiusCard);
    final icon = genreIcon(genre.name);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.primary, deep],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  right: -16,
                  bottom: -16,
                  child: Icon(
                    icon,
                    size: 96,
                    color: AppColors.onPrimary.withValues(alpha: 0.07),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimens.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: c.accent, size: 26),
                      const Spacer(),
                      Text(
                        genre.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleLarge?.copyWith(
                          color: AppColors.onPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppDimens.xs),
                      Container(width: 24, height: 1, color: c.accent),
                      const SizedBox(height: AppDimens.xs),
                      Text(
                        genre.bookCount == 1
                            ? '1 BOOK'
                            : '${genre.bookCount} BOOKS',
                        style: t.labelMedium?.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.75),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
