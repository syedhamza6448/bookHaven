import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/catalog/data/category_repository.dart';
import 'package:flutter/material.dart';

class AuthorTile extends StatelessWidget {
  const AuthorTile({super.key, required this.author, required this.onTap});

  final CategoryAuthor author;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusInput),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surface,
                border: Border.all(color: c.accent, width: 1.2),
              ),
              child: Text(
                author.initials,
                style: t.titleLarge?.copyWith(color: c.primary),
              ),
            ),
            const SizedBox(width: AppDimens.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    author.bookCount == 1
                        ? '1 book'
                        : '${author.bookCount} books',
                    style: t.bodySmall?.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
