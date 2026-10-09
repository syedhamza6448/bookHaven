import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bookhaven/features/admin/data/admin_user.dart';
import 'package:bookhaven/features/admin/data/admin_users_repository.dart';

import 'admin_dashboard_providers.dart';

class AdminUsersState {
  const AdminUsersState({
    this.items = const [],
    this.total = 0,
    this.counts = const {},
    this.query = '',
    this.filter = AdminUserFilter.all,
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.error,
  });

  final List<AdminUser> items;
  final int total;
  final Map<String, int> counts;
  final String query;
  final AdminUserFilter filter;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;

  AdminUsersState copyWith({
    List<AdminUser>? items,
    int? total,
    Map<String, int>? counts,
    String? query,
    AdminUserFilter? filter,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) => AdminUsersState(
    items: items ?? this.items,
    total: total ?? this.total,
    counts: counts ?? this.counts,
    query: query ?? this.query,
    filter: filter ?? this.filter,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
  );
}

class AdminUsersController extends Notifier<AdminUsersState> {
  Timer? _debounce;
  int _token = 0;

  @override
  AdminUsersState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(() {
      if (ref.mounted) refresh();
    });
    return const AdminUsersState();
  }

  String _msg(Object e) => e is AdminUserActionException
      ? e.message
      : 'Something went wrong. Try again.';

  Future<void> refresh() async {
    final token = ++_token;
    state = state.copyWith(loading: true, loadingMore: false, clearError: true);
    try {
      final page = await ref
          .read(adminUsersRepositoryProvider)
          .fetchPage(query: state.query, filter: state.filter, offset: 0);
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(
        items: page.items,
        total: page.total,
        counts: page.counts,
        loading: false,
        hasMore: page.items.length < page.total,
      );
    } catch (e) {
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(loading: false, error: _msg(e));
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final token = _token;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await ref
          .read(adminUsersRepositoryProvider)
          .fetchPage(
            query: state.query,
            filter: state.filter,
            offset: state.items.length,
          );
      if (!ref.mounted || token != _token) return;
      final all = [...state.items, ...page.items];
      state = state.copyWith(
        items: all,
        total: page.total,
        counts: page.counts,
        loadingMore: false,
        hasMore: all.length < page.total,
      );
    } catch (_) {
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(loadingMore: false);
    }
  }

  void setQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!ref.mounted) return;
      final value = q.trim();
      if (value == state.query) return;
      state = state.copyWith(query: value, items: const []);
      refresh();
    });
  }

  void setFilter(AdminUserFilter f) {
    if (f == state.filter) return;
    state = state.copyWith(filter: f, items: const []);
    refresh();
  }

  /// Throws [AdminUserActionException] on failure.
  Future<void> setRole(String userId, String role) async {
    await ref.read(adminUsersRepositoryProvider).setRole(userId, role);
    ref.invalidate(adminDashboardProvider);
    if (ref.mounted) refresh();
  }
}

final adminUsersControllerProvider =
    NotifierProvider.autoDispose<AdminUsersController, AdminUsersState>(
      AdminUsersController.new,
    );
