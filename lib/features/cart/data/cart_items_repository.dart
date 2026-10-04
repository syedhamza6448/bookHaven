import 'package:bookhaven/shared/models/book.dart';
import 'package:bookhaven/shared/models/cart_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final cartItemsRepositoryProvider = Provider<CartItemsRepository>(
  (ref) => CartItemsRepository(Supabase.instance.client),
);

class CartItemsRepository {
  CartItemsRepository(this._client);
  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  Future<List<CartItem>> fetch() async {
    final rows = await _client
        .from('cart_items')
        .select('quantity, updated_at, books(*, authors(name), genres(name))')
        .eq('user_id', _uid)
        .order('updated_at', ascending: false);

    final items = <CartItem>[];
    for (final row in rows) {
      final raw = row['books'];
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      map['genre'] = map['genres'];
      items.add(
        CartItem(
          book: Book.fromJson(map),
          quantity: (row['quantity'] as num).toInt(),
        ),
      );
    }
    return items;
  }

  Future<void> setQuantity(String bookId, int quantity) => _client
      .from('cart_items')
      .update({
        'quantity': quantity,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('user_id', _uid)
      .eq('book_id', bookId);

  Future<void> remove(String bookId) => _client
      .from('cart_items')
      .delete()
      .eq('user_id', _uid)
      .eq('book_id', bookId);

  Future<void> restore(String bookId, int quantity) =>
      _client.from('cart_items').upsert({
        'user_id': _uid,
        'book_id': bookId,
        'quantity': quantity,
      }, onConflict: 'user_id,book_id');

  Future<void> clear() =>
      _client.from('cart_items').delete().eq('user_id', _uid);
}
