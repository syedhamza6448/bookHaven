import 'package:bookhaven/shared/models/book.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookDetails {
  const BookDetails({required this.book, this.genreId, this.authorId});
  final Book book;
  final String? genreId;
  final String? authorId;
}

final bookDetailsRepositoryProvider = Provider<BookDetailsRepository>(
  (ref) => BookDetailsRepository(Supabase.instance.client),
);

class BookDetailsRepository {
  BookDetailsRepository(this._client);
  final SupabaseClient _client;

  static const _select = '*, authors(name), genres(name)';

  Future<BookDetails> fetchBook(String id) async {
    final json = await _client
        .from('books')
        .select(_select)
        .eq('id', id)
        .single();
    return BookDetails(
      book: Book.fromJson(json),
      genreId: json['genre_id']?.toString(),
      authorId: json['author_id']?.toString(),
    );
  }

  Future<List<Book>> fetchRelated({
    required String bookId,
    required String? genreId,
    int limit = 10,
  }) async {
    if (genreId == null) return [];
    final rows = await _client
        .from('books')
        .select(_select)
        .eq('genre_id', genreId)
        .neq('id', bookId)
        .order('sales_count', ascending: true)
        .limit(limit);
    return rows.map(Book.fromJson).toList();
  }
}
