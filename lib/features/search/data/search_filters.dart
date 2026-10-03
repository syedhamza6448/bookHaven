import 'package:bookhaven/features/catalog/data/book_sort.dart';

class SearchFilters {
  const SearchFilters({
    this.genreIds = const <String>{},
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.inStockOnly = false,
    this.sort = BookSort.popular,
  });

  final Set<String> genreIds;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool inStockOnly;
  final BookSort sort;

  int get activeCount =>
      (genreIds.isNotEmpty ? 1 : 0) +
      ((minPrice != null || maxPrice != null) ? 1 : 0) +
      (minRating != null ? 1 : 0) +
      (inStockOnly ? 1 : 0);

  SearchFilters copyWith({Set<String>? genreIds, BookSort? sort}) =>
      SearchFilters(
        genreIds: genreIds ?? this.genreIds,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        inStockOnly: inStockOnly,
        sort: sort ?? this.sort,
      );
}
