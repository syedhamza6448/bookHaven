import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/theme/theme_provider.dart';
import 'package:bookhaven/features/auth/data/auth_repository.dart';
import 'package:bookhaven/features/cart/presentation/providers/cart_controller.dart';
import 'package:bookhaven/features/profile/presentation/providers/profile_providers.dart';
import 'package:bookhaven/features/profile/presentation/widgets/profile_header.dart';
import 'package:bookhaven/features/profile/presentation/widgets/profile_menu.dart';
import 'package:bookhaven/features/profile/presentation/widgets/profile_stats_row.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what is coming soon')));
  }

  void _toggleTheme(WidgetRef ref, bool isDark) {
    // Adjust this line if your themeModeProvider notifier uses a different method
    ref
        .read(themeModeProvider.notifier)
        .setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to shop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(profileProvider);
    ref.invalidate(profileStatsProvider);
    ref.invalidate(cartControllerProvider);
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final profile = ref.watch(profileProvider);
    final stats = ref.watch(profileStatsProvider);
    final isAdmin = profile.value?.isAdmin ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: c.bg,
        body: RefreshIndicator(
          color: c.primary,
          onRefresh: () async {
            ref.invalidate(profileProvider);
            ref.invalidate(profileStatsProvider);
            try {
              await ref.read(profileProvider.future);
            } catch (_) {}
          },
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              profile.when(
                data: (p) => ProfileHeader(profile: p),
                loading: () => const ProfileHeaderSkeleton(),
                error: (_, _) => ProfileHeaderError(
                  onRetry: () {
                    ref.invalidate(profileProvider);
                    ref.invalidate(profileStatsProvider);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.pagePadding,
                  20,
                  AppDimens.pagePadding,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileStatsRow(stats: stats.value),
                    const SizedBox(height: 24),
                    ProfileMenuSection(
                      title: 'Account',
                      children: [
                        ProfileMenuTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit profile',
                          subtitle: 'Name and photo',
                          onTap: () => context.push(AppRoutes.editProfile),
                        ),
                        ProfileMenuTile(
                          icon: Icons.location_on_outlined,
                          title: 'Addresses & payment methods',
                          subtitle: 'Where and how you pay',
                          onTap: () => _soon(context, 'Addresses & payments'),
                        ),
                        ProfileMenuTile(
                          icon: Icons.receipt_long_outlined,
                          title: 'My orders',
                          subtitle: 'History and delivery tracking',
                          onTap: () => _soon(context, 'Order history'),
                        ),
                        ProfileMenuTile(
                          icon: Icons.bookmark_border_rounded,
                          title: 'Wishlist',
                          subtitle: 'Books you want to read next',
                          onTap: () => context.go(AppRoutes.wishlist),
                        ),
                        if (isAdmin)
                          ProfileMenuTile(
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'Admin dashboard',
                            subtitle: 'Manage books, users and orders',
                            onTap: () => context.push(AppRoutes.adminDashboard),
                          ),
                      ],
                    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04),
                    const SizedBox(height: 24),
                    ProfileMenuSection(
                          title: 'Settings',
                          children: [
                            ProfileMenuTile(
                              icon: c.isDark
                                  ? Icons.dark_mode_outlined
                                  : Icons.light_mode_outlined,
                              title: 'Dark mode',
                              subtitle: 'Midnight Library theme',
                              onTap: () => _toggleTheme(ref, c.isDark),
                              trailing: Switch(
                                value: c.isDark,
                                onChanged: (_) => _toggleTheme(ref, c.isDark),
                              ),
                            ),
                          ],
                        )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.04),
                    const SizedBox(height: 24),
                    ProfileMenuSection(
                          title: 'Support',
                          children: [
                            ProfileMenuTile(
                              icon: Icons.help_outline_rounded,
                              title: 'Help & FAQ',
                              onTap: () => _soon(context, 'Help & FAQ'),
                            ),
                            ProfileMenuTile(
                              icon: Icons.logout_rounded,
                              title: 'Sign out',
                              destructive: true,
                              onTap: () => _confirmSignOut(context, ref),
                            ),
                          ],
                        )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.04),
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        'bookHaven 1.0.0',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: c.textSecondary),
                      ),
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
