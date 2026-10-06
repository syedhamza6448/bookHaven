import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/shared/models/book.dart';

class WishlistException implements Exception {
  WishlistException(this.message);
  final String message;

  @override
  String toString() => message;
}

final wishlistItemsRepositoryProvider = Provider<WishlistItemsRepository>(
  (ref) => WishlistItemsRepository(),
);

class WishlistItemsRepository {
  SupabaseClient get _db => Supabase.instance.client;

  /// Newest saved first.
  Future<List<Book>> fetchAll() async {
    final rows = await _db
        .from('wishlist')
        .select('created_at, books(*, authors(name), genres(name))')
        .order('created_at', ascending: false);

    final books = <Book>[];
    for (final row in rows) {
      final raw = row['books'];
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      map['genre'] = map['genres']; // Book.fromJson reads 'genre'
      books.add(Book.fromJson(map));
    }
    return books;
  }

  Future<void> remove(String bookId) async {
    await _db.from('wishlist').delete().eq('book_id', bookId);
  }

  Future<void> restore(String bookId) async {
    await _db.from('wishlist').insert({'book_id': bookId});
  }

  Future<void> moveToCart(String bookId) async {
    try {
      await _db.rpc('move_wishlist_to_cart', params: {'p_book_id': bookId});
    } on PostgrestException catch (e) {
      throw WishlistException(e.message);
    }
  }
}
