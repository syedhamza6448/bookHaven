import 'package:bookhaven/shared/models/book.dart';
import 'package:bookhaven/shared/models/genre.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => BookRepository(),
);

class BookRepository {
  SupabaseClient get _db => Supabase.instance.client;

  static const _select = '*, authors(name). genres(name)';

  Future<List<Book>> bestsellers({int limit = 10}) async {
    final data = await _db
        .from('books')
        .select(_select)
        .order('sales_count', ascending: false)
        .limit(limit);
    return data.map(Book.fromJson).toList();
  }

  Future<List<Book>> newArrivals({int limit = 10}) async {
    final data = await _db
        .from('books')
        .select(_select)
        .order('published_at', ascending: false)
        .limit(limit);
    return data.map(Book.fromJson).toList();
  }

  Future<Book?> featuredBook() async {
    final data = await _db
        .from('books')
        .select(_select)
        .eq('is_featured', true)
        .limit(1)
        .maybeSingle();
    return data == null ? null : Book.fromJson(data);
  }

  Future<List<Genre>> genres() async {
    final data = await _db.from('genres').select().order('name');
    return data.map(Genre.fromJson).toList();
  }
}
