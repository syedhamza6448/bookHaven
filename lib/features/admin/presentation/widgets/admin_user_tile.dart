import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/admin/data/admin_user.dart';

class AdminUserAvatar extends StatelessWidget {
  const AdminUserAvatar({super.key, required this.user, this.radius = 24});
  final AdminUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final url = user.avatarUrl;
    final hasImage = url != null && url.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.accent, width: 1.5),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: c.primary.withValues(alpha: 0.12),
        backgroundImage: hasImage ? CachedNetworkImageProvider(url) : null,
        child: hasImage
            ? null
            : Text(
                user.initial,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: radius * 0.9,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                ),
              ),
      ),
    );
  }
}

class AdminRoleBadge extends StatelessWidget {
  const AdminRoleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.accent.withValues(alpha: 0.6)),
      ),
      child: Text(
        'ADMIN',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: c.accent,
        ),
      ),
    );
  }
}

class AdminUserTile extends StatelessWidget {
  const AdminUserTile({super.key, required this.user, required this.onTap});
  final AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final orders =
        '${user.orderCount} ${user.orderCount == 1 ? 'order' : 'orders'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          side: BorderSide(color: c.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AdminUserAvatar(user: user),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.titleMedium?.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (user.isAdmin) ...[
                            const SizedBox(width: 8),
                            const AdminRoleBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$orders  ·  ${formatPrice(user.totalSpent)} spent',
                        style: t.bodySmall?.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
