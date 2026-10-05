import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    this.avatarUrl,
    this.onAvatarTap,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'GOOD MORNING';
    if (h < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = name.isEmpty ? 'Reader' : name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        AppDimens.lg,
        AppDimens.pagePadding,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: textTheme.labelMedium?.copyWith(color: context.accent),
                ),
                const SizedBox(height: 4),
                Text(
                  '$displayName.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'What will you read next?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.md),
          GestureDetector(
            onTap: onAvatarTap,
            behavior: HitTestBehavior.opaque,
            child: _Avatar(
              initial: displayName[0].toUpperCase(),
              url: avatarUrl,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, this.url});

  final String initial;
  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 46.0;

    final initialWidget = Text(
      initial,
      style: GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.onPrimary,
      ),
    );

    final hasUrl = url != null && url!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.primary,
        border: Border.all(color: context.accent, width: 1.5),
      ),
      child: hasUrl
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => Center(child: initialWidget),
                errorWidget: (_, __, ___) => Center(child: initialWidget),
              ),
            )
          : initialWidget,
    );
  }
}
