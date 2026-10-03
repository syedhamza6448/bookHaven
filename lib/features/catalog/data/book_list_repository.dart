import 'package:bookhaven/features/catalog/data/book_sort.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final bookListRepositoryProvider = Provider<BookListRepository>(
  (ref) => BookListRepository(),
);

class BookListRepository {
  static const pageSize = 12;

  Future<List<Book>> fetchPage({
    String? genreId,
    String? authorId,
    required BookSort sort,
    required int page,
  }) async {
    var query = Supabase.instance.client
        .from('books')
        .select('*, authors(name), genres(name)');

    if (genreId != null && genreId.isNotEmpty) {
      query = query.eq('genre_id', genreId);
    }
    if (authorId != null && authorId.isNotEmpty) {
      query = query.eq('author_id', authorId);
    }

    final from = page * pageSize;
    final rows = await query
        .order(sort.column, ascending: sort.ascending, nullsFirst: false)
        .order('id')
        .range(from, from + pageSize - 1);

    return rows.map<Book>((row) => Book.fromJson(row)).toList();
  }
}
