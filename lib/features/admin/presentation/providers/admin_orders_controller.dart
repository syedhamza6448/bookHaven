import 'dart:async';

import 'package:bookhaven/features/admin/data/admin_order.dart';
import 'package:bookhaven/features/admin/data/admin_orders_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrdersState {
  const AdminOrdersState({
    this.items = const [],
    this.total = 0,
    this.counts = const {},
    this.query = '',
    this.filter = AdminOrderFilter.all,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<AdminOrder> items;
  final int total;
  final Map<String, int> counts;
  final String query;
  final AdminOrderFilter filter;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => items.length < total;

  int countFor(AdminOrderFilter f) => f == AdminOrderFilter.all
      ? counts.values.fold(0, (a, b) => a + b)
      : (counts[f.value] ?? 0);

  AdminOrdersState copyWith({
    List<AdminOrder>? items,
    int? total,
    Map<String, int>? counts,
    String? query,
    AdminOrderFilter? filter,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return AdminOrdersState(
      items: items ?? this.items,
      total: total ?? this.total,
      counts: counts ?? this.counts,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminOrdersController extends Notifier<AdminOrdersState> {
  Timer? _debounce;
  int _token = 0;

  AdminOrdersRepository get _repo => ref.read(adminOrdersRepositoryProvider);

  @override
  AdminOrdersState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(refresh);
    return const AdminOrdersState(isLoading: true);
  }

  Future<void> refresh() async {
    final token = ++_token;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );
    try {
      final page = await _repo.fetchPage(
        query: state.query,
        filter: state.filter,
        offset: 0,
      );
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(
        items: page.items,
        total: page.total,
        counts: page.counts,
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(isLoading: false, error: _message(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final token = _token;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repo.fetchPage(
        query: state.query,
        filter: state.filter,
        offset: state.items.length,
      );
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(
        items: [...state.items, ...page.items],
        total: page.total,
        counts: page.counts,
        isLoadingMore: false,
      );
    } catch (_) {
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setQuery(String value) {
    final q = value.trim();
    if (q == state.query) return;
    state = state.copyWith(query: q);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), refresh);
  }

  void setFilter(AdminOrderFilter filter) {
    if (filter == state.filter) return;
    _debounce?.cancel();
    state = state.copyWith(filter: filter, items: const [], total: 0);
    refresh();
  }

  String _message(Object e) {
    if (e is PostgrestException) return e.message;
    return 'Could not load orders. Please try again.';
  }
}

final adminOrdersControllerProvider =
    NotifierProvider.autoDispose<AdminOrdersController, AdminOrdersState>(
      AdminOrdersController.new,
    );
