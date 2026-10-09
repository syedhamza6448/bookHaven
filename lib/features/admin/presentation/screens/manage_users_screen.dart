import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/admin/data/admin_user.dart';

import '../providers/admin_users_controller.dart';
import '../widgets/admin_user_sheet.dart';
import '../widgets/admin_user_tile.dart';

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        ref.read(adminUsersControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final s = ref.watch(adminUsersControllerProvider);
    final ctrl = ref.read(adminUsersControllerProvider.notifier);

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          _Header(total: s.counts['all'] ?? s.total),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadding,
              16,
              AppDimens.pagePadding,
              8,
            ),
            child: TextField(
              controller: _search,
              onChanged: ctrl.setQuery,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                hintStyle: TextStyle(color: c.textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded, color: c.textSecondary),
                        onPressed: () {
                          _search.clear();
                          ctrl.setQuery('');
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: c.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                  borderSide: BorderSide(color: c.primary, width: 1.4),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.pagePadding,
              ),
              children: [
                for (final f in AdminUserFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        s.counts[f.value] == null
                            ? f.label
                            : '${f.label} (${s.counts[f.value]})',
                      ),
                      selected: s.filter == f,
                      onSelected: (_) => ctrl.setFilter(f),
                      showCheckmark: false,
                      selectedColor: c.primary,
                      backgroundColor: c.surface,
                      side: BorderSide(
                        color: s.filter == f ? c.primary : c.border,
                      ),
                      labelStyle: TextStyle(
                        color: s.filter == f
                            ? AppColors.onPrimary
                            : c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _body(context, s)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AdminUsersState s) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final ctrl = ref.read(adminUsersControllerProvider.notifier);

    if (s.loading && s.items.isEmpty) return const _UsersSkeleton();

    if (s.error != null && s.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 40, color: c.textSecondary),
              const SizedBox(height: 12),
              Text(
                s.error!,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: c.error),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: ctrl.refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (s.items.isEmpty) {
      return Center(
        child: Text(
          s.query.isEmpty ? 'No users yet.' : 'No users match "${s.query}".',
          style: t.bodyMedium?.copyWith(color: c.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      color: c.primary,
      onRefresh: ctrl.refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadding,
          12,
          AppDimens.pagePadding,
          32,
        ),
        itemCount: s.items.length + 1,
        itemBuilder: (context, i) {
          if (i == s.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: s.loadingMore
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        s.hasMore ? '' : "THAT'S EVERYONE",
                        style: t.labelMedium?.copyWith(
                          color: c.textSecondary,
                          letterSpacing: 1.6,
                        ),
                      ),
              ),
            );
          }
          final user = s.items[i];
          return AdminUserTile(
            key: ValueKey(user.id),
            user: user,
            onTap: () => showAdminUserSheet(context, user),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, Color.lerp(c.primary, Colors.black, 0.3)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, AppDimens.pagePadding, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.onPrimary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: c.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage users',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    Text(
                      '$total ${total == 1 ? 'reader' : 'readers'} in the library',
                      style: TextStyle(
                        color: AppColors.onPrimary.withValues(alpha: 0.75),
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

class _UsersSkeleton extends StatelessWidget {
  const _UsersSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Shimmer.fromColors(
      baseColor: c.border,
      highlightColor: c.surface,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.pagePadding),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 84,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: c.border,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          ),
        ),
      ),
    );
  }
}
