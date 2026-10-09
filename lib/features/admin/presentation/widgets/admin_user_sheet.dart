import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/admin/data/admin_user.dart';
import 'package:bookhaven/features/admin/data/admin_users_repository.dart';

import '../providers/admin_user_detail_providers.dart';
import '../providers/admin_users_controller.dart';
import 'admin_user_tile.dart';

Future<void> showAdminUserSheet(BuildContext context, AdminUser user) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AdminUserSheet(user: user),
  );
}

class AdminUserSheet extends ConsumerStatefulWidget {
  const AdminUserSheet({super.key, required this.user});
  final AdminUser user;

  @override
  ConsumerState<AdminUserSheet> createState() => _AdminUserSheetState();
}

class _AdminUserSheetState extends ConsumerState<AdminUserSheet> {
  late String _role = widget.user.role;
  bool _busy = false;

  bool get _isSelf =>
      Supabase.instance.client.auth.currentUser?.id == widget.user.id;

  Future<void> _changeRole() async {
    final makeAdmin = _role != 'admin';
    final name = widget.user.displayName;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(makeAdmin ? 'Make admin?' : 'Remove admin?'),
        content: Text(
          makeAdmin
              ? '$name will get full access to the admin panel.'
              : '$name will lose access to the admin panel and become a regular customer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(makeAdmin ? 'Make admin' : 'Remove admin'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    final newRole = makeAdmin ? 'admin' : 'user';
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(adminUsersControllerProvider.notifier)
          .setRole(widget.user.id, newRole);
      if (!mounted) return;
      setState(() {
        _role = newRole;
        _busy = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            makeAdmin ? '$name is now an admin.' : '$name is now a customer.',
          ),
        ),
      );
    } on AdminUserActionException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update the role.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final user = widget.user;
    final detail = ref.watch(adminUserDetailProvider(user.id));
    final isAdmin = _role == 'admin';

    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                AdminUserAvatar(user: user, radius: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        user.email,
                        style: t.bodySmall?.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (isAdmin)
                            const AdminRoleBadge()
                          else
                            Text(
                              'CUSTOMER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: c.textSecondary,
                              ),
                            ),
                          const SizedBox(width: 10),
                          Text(
                            'Joined ${DateFormat('MMM d, yyyy').format(user.createdAt)}',
                            style: t.bodySmall?.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            detail.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      e is AdminUserActionException
                          ? e.message
                          : 'Could not load this user.',
                      style: t.bodyMedium?.copyWith(color: c.error),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(adminUserDetailProvider(user.id)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (d) => _DetailBody(detail: d),
            ),
            const SizedBox(height: 20),
            if (_isSelf)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Text(
                  'This is your account. You can\'t change your own role.',
                  style: t.bodySmall?.copyWith(color: c.textSecondary),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _changeRole,
                  style: FilledButton.styleFrom(
                    backgroundColor: isAdmin ? c.error : c.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isAdmin
                              ? Icons.shield_outlined
                              : Icons.admin_panel_settings_outlined,
                        ),
                  label: Text(isAdmin ? 'Remove admin' : 'Make admin'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});
  final AdminUserDetail detail;

  static const _labels = {
    'placed': 'Placed',
    'processing': 'Processing',
    'shipped': 'Shipped',
    'out_for_delivery': 'Out for delivery',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final u = detail.user;

    Widget stat(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            stat('${u.orderCount}', 'Orders'),
            const SizedBox(width: 8),
            stat(formatPrice(u.totalSpent), 'Spent'),
            const SizedBox(width: 8),
            stat('${detail.reviewsCount}', 'Reviews'),
            const SizedBox(width: 8),
            stat('${detail.wishlistCount}', 'Wishlist'),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'RECENT ORDERS',
          style: t.labelMedium?.copyWith(
            color: c.textSecondary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: c.accent.withValues(alpha: 0.5), height: 1),
        if (detail.recentOrders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'No orders yet.',
              style: t.bodyMedium?.copyWith(color: c.textSecondary),
            ),
          )
        else
          for (final o in detail.recentOrders)
            InkWell(
              onTap: () {
                final router = GoRouter.of(context);
                Navigator.pop(context);
                router.push(AppRoutes.adminOrderDetailPath(o.id));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.orderNumber,
                            style: t.bodyMedium?.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(o.createdAt),
                            style: t.bodySmall?.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(o.total),
                          style: t.bodyMedium?.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _labels[o.status] ?? o.status,
                          style: t.bodySmall?.copyWith(
                            color: o.status == 'delivered'
                                ? c.primary
                                : o.status == 'cancelled'
                                ? c.error
                                : c.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: c.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
