import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(Supabase.instance.client),
);

class CartRepository {
  CartRepository(this._client);
  final SupabaseClient _client;

  /// Adds [quantity] copies, never exceeding [stock]. Returns the new quantity in the cart.
  Future<int> addItem({
    required String bookId,
    required int quantity,
    required int stock,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Please sign in first.');

    final existing = await _client
        .from('cart_items')
        .select('quantity')
        .eq('user_id', uid)
        .eq('book_id', bookId)
        .maybeSingle();
    final current = (existing?['quantity'] as num?)?.toInt() ?? 0;
    final next = math.min(current + quantity, stock);

    await _client.from('cart_items').upsert({
      'user_id': uid,
      'book_id': bookId,
      'quantity': next,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,book_id');
    return next;
  }
}
