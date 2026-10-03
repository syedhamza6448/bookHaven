import 'package:bookhaven/features/search/data/search_filters.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchPage {
  const SearchPage({required this.books, required this.total});
  final List<Book> books;
  final int total;
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(),
);
final recentSearchesStoreProvider = Provider<RecentSearchesStore>(
  (ref) => RecentSearchesStore(),
);

class SearchRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<SearchPage> search({
    required String query,
    required SearchFilters filters,
    required int page,
    required int pageSize,
  }) async {
    final res = await _db.rpc(
      'search_book_ids',
      params: {
        'p_query': query.trim(),
        'p_genre_ids': filters.genreIds.toList(),
        'p_min_price': filters.minPrice,
        'p_max_price': filters.maxPrice,
        'p_min_rating': filters.minRating,
        'p_in_stock': filters.inStockOnly,
        'p_sort':
            filters.sort.name, // popular, newest, rating, priceLow, priceHigh
        'p_limit': pageSize,
        'p_offset': page * pageSize,
      },
    );

    final rows = (res as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const SearchPage(books: [], total: 0);

    final total = (rows.first['total_count'] as num).toInt();
    final ids = rows.map((r) => r['book_id'].toString()).toList();

    final data = await _db
        .from('books')
        .select('*, authors(name), genres(name)')
        .inFilter('id', ids);

    final byId = {for (final r in data) r['id'].toString(): Book.fromJson(r)};
    final books = ids.map((id) => byId[id]).whereType<Book>().toList();
    return SearchPage(books: books, total: total);
  }

  /// Highest book price, rounded up, used as the slider maximum.
  Future<double> maxPrice() async {
    final rows = await _db
        .from('books')
        .select('price')
        .order('price', ascending: false)
        .limit(1);
    if (rows.isEmpty) return 100;
    final p = (rows.first['price'] as num).toDouble().ceilToDouble();
    return p < 10 ? 10 : p;
  }
}

class RecentSearchesStore {
  static const _key = 'recent_searches';
  static const _max = 8;

  Future<List<String>> load() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_key) ?? <String>[];
  }

  Future<List<String>> add(String query) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key) ?? <String>[];
    list.removeWhere((e) => e.toLowerCase() == query.toLowerCase());
    list.insert(0, query);
    final trimmed = list.take(_max).toList();
    await p.setStringList(_key, trimmed);
    return trimmed;
  }

  Future<List<String>> remove(String query) async {
    final p = await SharedPreferences.getInstance();
    final list = (p.getStringList(_key) ?? <String>[])..remove(query);
    await p.setStringList(_key, list);
    return list;
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
