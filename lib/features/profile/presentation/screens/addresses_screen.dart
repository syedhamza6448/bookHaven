import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/profile/data/address_manage_repository.dart';
import 'package:bookhaven/features/profile/data/address_repository.dart';
import 'package:bookhaven/features/profile/presentation/providers/address_providers.dart';
import 'package:bookhaven/features/profile/presentation/widgets/address_editor_sheet.dart';
import 'package:bookhaven/shared/models/address.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  String? _busyId;

  void _snack(String message, {bool error = false}) {
    final c = context.palette;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? c.error : null,
        ),
      );
  }

  Future<void> _run(
    String id,
    Future<void> Function() action,
    String success,
  ) async {
    setState(() => _busyId = id);
    try {
      await action();
      ref.invalidate(addressesProvider);
      if (mounted) _snack(success);
    } catch (e) {
      if (mounted) {
        _snack(
          kDebugMode ? '$e' : 'Something went wrong. Please try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _add() async {
    final isFirst =
        (ref.read(addressesProvider).value ?? const <Address>[]).isEmpty;
    final saved = await showAddressEditorSheet(context, isFirst: isFirst);
    if (saved == true && mounted) _snack('Address saved');
  }

  Future<void> _edit(Address a) async {
    final saved = await showAddressEditorSheet(context, existing: a);
    if (saved == true && mounted) _snack('Address updated');
  }

  Future<void> _delete(Address a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text(
          'Remove "${a.label}" from your address book? '
          'Your past orders will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: ctx.palette.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(
      a.id,
      () => ref.read(addressRepositoryProvider).deleteAddress(a.id),
      'Address deleted',
    );
  }

  Future<void> _makeDefault(Address a) => _run(
    a.id,
    () => ref.read(addressRepositoryProvider).setDefaultAddress(a.id),
    'Default address updated',
  );

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final async = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: async.when(
              skipLoadingOnReload: true,
              loading: () => const _Skeleton(),
              error: (e, _) =>
                  _ErrorView(onRetry: () => ref.invalidate(addressesProvider)),
              data: (list) {
                if (list.isEmpty) return _EmptyView(onAdd: _add);
                return RefreshIndicator(
                  color: c.primary,
                  onRefresh: () async {
                    ref.invalidate(addressesProvider);
                    await ref.read(addressesProvider.future);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.pagePadding,
                      AppDimens.xl,
                      AppDimens.pagePadding,
                      AppDimens.xl,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final a = list[i];
                      return _AddressCard(
                            address: a,
                            busy: _busyId != null,
                            onEdit: () => _edit(a),
                            onDelete: () => _delete(a),
                            onMakeDefault: () => _makeDefault(a),
                          )
                          .animate(delay: Duration(milliseconds: 60 * i))
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.06, curve: Curves.easeOut);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.pagePadding,
            AppDimens.sm,
            AppDimens.pagePadding,
            AppDimens.md,
          ),
          child: SizedBox(
            height: AppDimens.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: _busyId == null ? _add : null,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add new address'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimens.sm,
        MediaQuery.of(context).padding.top + AppDimens.sm,
        AppDimens.pagePadding,
        AppDimens.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, Color.lerp(c.primary, Colors.black, 0.35)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.onPrimary,
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppDimens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR ADDRESS BOOK',
                  style: t.labelMedium?.copyWith(color: AppColors.darkAccent),
                ),
                const SizedBox(height: AppDimens.xs),
                Text(
                  'Addresses',
                  style: t.headlineMedium?.copyWith(color: AppColors.onPrimary),
                ),
                const SizedBox(height: AppDimens.md),
                Container(width: 48, height: 2, color: AppColors.darkAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onMakeDefault,
  });

  final Address address;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMakeDefault;

  IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('home')) return Icons.home_outlined;
    if (l.contains('work') || l.contains('office')) {
      return Icons.work_outline_rounded;
    }
    return Icons.place_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final a = address;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: a.isDefault ? c.accent : c.border,
          width: a.isDefault ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconFor(a.label),
                        size: 18,
                        color: c.primary,
                      ),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                      child: Text(
                        a.label.toUpperCase(),
                        style: t.labelMedium?.copyWith(color: c.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (a.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: c.accent),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: t.labelMedium?.copyWith(
                            color: c.accent,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                Text(
                  a.fullName,
                  style: t.titleMedium?.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: AppDimens.xs),
                Text(
                  a.oneLine,
                  style: t.bodyMedium?.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: AppDimens.xs),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 15,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      a.phone,
                      style: t.bodyMedium?.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.sm),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: busy ? null : onDelete,
                  style: TextButton.styleFrom(foregroundColor: c.error),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                ),
                const Spacer(),
                if (!a.isDefault)
                  TextButton(
                    onPressed: busy ? null : onMakeDefault,
                    child: const Text('Set as default'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, size: 56, color: c.accent),
            const SizedBox(height: AppDimens.lg),
            Text('No addresses yet', style: t.headlineSmall),
            const SizedBox(height: AppDimens.sm),
            Text(
              'Add a delivery address so checkout is one tap away.',
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppDimens.xl),
            OutlinedButton(onPressed: onAdd, child: const Text('Add address')),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: c.textSecondary),
            const SizedBox(height: AppDimens.lg),
            Text('Could not load your addresses', style: t.titleMedium),
            const SizedBox(height: AppDimens.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return Shimmer.fromColors(
      baseColor: c.border,
      highlightColor: c.surface,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.pagePadding),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          height: 150,
          margin: const EdgeInsets.only(bottom: AppDimens.md),
          decoration: BoxDecoration(
            color: c.border,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          ),
        ),
      ),
    );
  }
}
