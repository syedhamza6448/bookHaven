import 'package:bookhaven/features/catalog/data/book_list_repository.dart';
import 'package:bookhaven/features/catalog/data/book_sort.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookListArgs {
  const BookListArgs({
    this.title = 'All Books',
    this.genreId,
    this.authorId,
    this.sort = BookSort.popular,
  });

  final String title;
  final String? genreId;
  final String? authorId;
  final BookSort sort;

  factory BookListArgs.fromQuery(Map<String, String> q) => BookListArgs(
    title: q['title'] ?? 'All Books',
    genreId: q['genre'],
    authorId: q['author'],
    sort: BookSort.fromName(q['sort']),
  );

  @override
  bool operator ==(Object other) =>
      other is BookListArgs &&
      other.title == title &&
      other.genreId == genreId &&
      other.authorId == authorId &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(title, genreId, authorId, sort);
}

class BookListState {
  const BookListState({
    required this.sort,
    this.genreId,
    this.books = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.loadMoreFailed = false,
    this.isGrid = true,
    this.error,
  });

  final BookSort sort;
  final String? genreId;
  final List<Book> books;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool loadMoreFailed;
  final bool isGrid;
  final String? error;

  BookListState copyWith({
    BookSort? sort,
    String? genreId,
    bool clearGenre = false,
    List<Book>? books,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? loadMoreFailed,
    bool? isGrid,
    String? error,
    bool clearError = false,
  }) {
    return BookListState(
      sort: sort ?? this.sort,
      genreId: clearGenre ? null : (genreId ?? this.genreId),
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      isGrid: isGrid ?? this.isGrid,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BookListController extends Notifier<BookListState> {
  BookListController(this.args);

  final BookListArgs args;
  int _page = 0;
  int _requestId = 0;
  bool _alive = true;

  @override
  BookListState build() {
    _alive = true;
    ref.onDispose(() => _alive = false);
    Future.microtask(_loadFirst);
    return BookListState(sort: args.sort, genreId: args.genreId);
  }

  Future<void> refresh() => _loadFirst(keepBooks: true);

  Future<void> setGenre(String? genreId) {
    if (genreId == state.genreId) return Future.value();
    state = genreId == null
        ? state.copyWith(clearGenre: true)
        : state.copyWith(genreId: genreId);
    return _loadFirst();
  }

  Future<void> setSort(BookSort sort) {
    if (sort == state.sort) return Future.value();
    state = state.copyWith(sort: sort);
    return _loadFirst();
  }

  void toggleView() => state = state.copyWith(isGrid: !state.isGrid);

  Future<void> _loadFirst({bool keepBooks = false}) async {
    final id = ++_requestId;
    _page = 0;
    final showSkeleton = !keepBooks || state.books.isEmpty;
    state = state.copyWith(
      isLoading: showSkeleton,
      isLoadingMore: false,
      loadMoreFailed: false,
      hasMore: true,
      books: showSkeleton ? const [] : null,
      clearError: true,
    );
    try {
      final items = await ref
          .read(bookListRepositoryProvider)
          .fetchPage(
            genreId: state.genreId,
            authorId: args.authorId,
            sort: state.sort,
            page: 0,
          );
      if (!_alive || id != _requestId) return;
      state = state.copyWith(
        books: items,
        isLoading: false,
        hasMore: items.length == BookListRepository.pageSize,
      );
    } catch (_) {
      if (!_alive || id != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        error:
            'We could not load the books. Check your connection and try again.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.error != null) {
      return;
    }
    final id = _requestId;
    state = state.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final items = await ref
          .read(bookListRepositoryProvider)
          .fetchPage(
            genreId: state.genreId,
            authorId: args.authorId,
            sort: state.sort,
            page: _page + 1,
          );
      if (!_alive || id != _requestId) return;
      _page++;
      state = state.copyWith(
        books: [...state.books, ...items],
        isLoadingMore: false,
        hasMore: items.length == BookListRepository.pageSize,
      );
    } catch (_) {
      if (!_alive || id != _requestId) return;
      state = state.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }
}

final bookListControllerProvider = NotifierProvider.autoDispose
    .family<BookListController, BookListState, BookListArgs>(
      BookListController.new,
    );
