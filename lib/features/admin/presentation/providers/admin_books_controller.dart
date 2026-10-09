import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bookhaven/features/admin/data/admin_book.dart';
import 'package:bookhaven/features/admin/data/admin_books_repository.dart';
import 'package:bookhaven/features/admin/presentation/providers/admin_dashboard_providers.dart';

class AdminBooksState {
  const AdminBooksState({
    this.items = const [],
    this.total = 0,
    this.query = '',
    this.filter = AdminBookFilter.all,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final List<AdminBook> items;
  final int total;
  final String query;
  final AdminBookFilter filter;
  final bool loading;
  final bool loadingMore;
  final String? error;

  bool get hasMore => items.length < total;

  AdminBooksState copyWith({
    List<AdminBook>? items,
    int? total,
    String? query,
    AdminBookFilter? filter,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
  }) {
    return AdminBooksState(
      items: items ?? this.items,
      total: total ?? this.total,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminBooksController extends Notifier<AdminBooksState> {
  int _token = 0;
  Timer? _debounce;

  AdminBooksRepository get _repo => ref.read(adminBooksRepositoryProvider);

  @override
  AdminBooksState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(refresh);
    return const AdminBooksState();
  }

  Future<void> refresh({bool silent = false}) async {
    final token = ++_token;
    if (!silent) state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await _repo.fetchPage(
        query: state.query,
        filter: state.filter,
      );
      if (token != _token) return;
      state = state.copyWith(
        items: page.items,
        total: page.total,
        loading: false,
        loadingMore: false,
        clearError: true,
      );
    } catch (e) {
      if (token != _token) return;
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        error: e is AdminActionException
            ? e.message
            : 'Could not load books. Try again.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final token = _token;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repo.fetchPage(
        query: state.query,
        filter: state.filter,
        offset: state.items.length,
      );
      if (token != _token) return;
      state = state.copyWith(
        items: [...state.items, ...page.items],
        total: page.total,
        loadingMore: false,
      );
    } catch (_) {
      if (token == _token) state = state.copyWith(loadingMore: false);
    }
  }

  void setQuery(String q) {
    final value = q.trim();
    if (value == state.query) return;
    state = state.copyWith(query: value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), refresh);
  }

  void setFilter(AdminBookFilter f) {
    if (f == state.filter) return;
    state = state.copyWith(filter: f);
    refresh();
  }

  /// Throws [AdminActionException] on failure so the screen can show it.
  Future<void> deleteBook(AdminBook book) async {
    await _repo.deleteBook(book);
    state = state.copyWith(
      items: state.items.where((b) => b.id != book.id).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
    );
    ref.invalidate(adminDashboardProvider);
  }
}

final adminBooksControllerProvider =
    NotifierProvider.autoDispose<AdminBooksController, AdminBooksState>(
      AdminBooksController.new,
    );
