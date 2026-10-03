import 'dart:async';

import 'package:bookhaven/features/search/data/search_filters.dart';
import 'package:bookhaven/features/search/data/search_repository.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookSearchState {
  const BookSearchState({
    this.query = '',
    this.filters = const SearchFilters(),
    this.books = const [],
    this.total = 0,
    this.page = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.recent = const [],
  });

  final String query;
  final SearchFilters filters;
  final List<Book> books;
  final int total;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final List<String> recent;

  bool get hasCriteria => query.trim().isNotEmpty || filters.activeCount > 0;

  BookSearchState copyWith({
    String? query,
    SearchFilters? filters,
    List<Book>? books,
    int? total,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    List<String>? recent,
  }) => BookSearchState(
    query: query ?? this.query,
    filters: filters ?? this.filters,
    books: books ?? this.books,
    total: total ?? this.total,
    page: page ?? this.page,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
    recent: recent ?? this.recent,
  );
}

class BookSearchController extends Notifier<BookSearchState> {
  static const _pageSize = 12;
  Timer? _debounce;
  int _requestId = 0;

  @override
  BookSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_loadRecent);
    return const BookSearchState();
  }

  // ---------- public API ----------

  void init({String? query, String? genreId}) {
    var filters = state.filters;
    if (genreId != null && genreId.isNotEmpty) {
      filters = filters.copyWith(genreIds: {genreId});
    }
    state = state.copyWith(query: query ?? '', filters: filters);
    if (state.hasCriteria) _run();
  }

  void onQueryChanged(String value) {
    state = state.copyWith(query: value);
    _debounce?.cancel();
    if (!state.hasCriteria) {
      _reset();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _run);
  }

  void submit(String value) {
    _debounce?.cancel();
    state = state.copyWith(query: value);
    final q = value.trim();
    if (q.isNotEmpty) _saveRecent(q);
    state.hasCriteria ? _run() : _reset();
  }

  void rememberCurrentQuery() {
    final q = state.query.trim();
    if (q.isNotEmpty) _saveRecent(q);
  }

  void applyFilters(SearchFilters filters) {
    _debounce?.cancel();
    state = state.copyWith(filters: filters);
    state.hasCriteria ? _run() : _reset();
  }

  void clearFilters() => applyFilters(SearchFilters(sort: state.filters.sort));

  void retry() => _run();

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final id = _requestId;
    final next = state.page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final res = await ref
          .read(searchRepositoryProvider)
          .search(
            query: state.query,
            filters: state.filters,
            page: next,
            pageSize: _pageSize,
          );
      if (!ref.mounted || id != _requestId) return;
      state = state.copyWith(
        books: [...state.books, ...res.books],
        page: next,
        isLoadingMore: false,
        hasMore: (next + 1) * _pageSize < res.total,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> removeRecent(String q) async {
    final list = await ref.read(recentSearchesStoreProvider).remove(q);
    if (ref.mounted) state = state.copyWith(recent: list);
  }

  Future<void> clearRecent() async {
    await ref.read(recentSearchesStoreProvider).clear();
    if (ref.mounted) state = state.copyWith(recent: const []);
  }

  // ---------- internals ----------

  void _reset() {
    _requestId++;
    state = state.copyWith(
      books: const [],
      total: 0,
      page: 0,
      isLoading: false,
      isLoadingMore: false,
      hasMore: false,
      clearError: true,
    );
  }

  Future<void> _run() async {
    final id = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ref
          .read(searchRepositoryProvider)
          .search(
            query: state.query,
            filters: state.filters,
            page: 0,
            pageSize: _pageSize,
          );
      if (!ref.mounted || id != _requestId) return;
      state = state.copyWith(
        books: res.books,
        total: res.total,
        page: 0,
        isLoading: false,
        hasMore: _pageSize < res.total,
      );
    } catch (e, st) {
      debugPrint('SEARCH ERROR: $e\n$st');
      if (!ref.mounted || id != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        error: kDebugMode
            ? 'Search failed: $e'
            : 'Could not search right now. Please try again.',
      );
    }
  }

  Future<void> _loadRecent() async {
    final list = await ref.read(recentSearchesStoreProvider).load();
    if (ref.mounted) state = state.copyWith(recent: list);
  }

  Future<void> _saveRecent(String q) async {
    final list = await ref.read(recentSearchesStoreProvider).add(q);
    if (ref.mounted) state = state.copyWith(recent: list);
  }
}

final bookSearchControllerProvider =
    NotifierProvider.autoDispose<BookSearchController, BookSearchState>(
      BookSearchController.new,
    );

final searchMaxPriceProvider = FutureProvider.autoDispose<double>(
  (ref) => ref.read(searchRepositoryProvider).maxPrice(),
  retry: (retryCount, error) => null,
);
