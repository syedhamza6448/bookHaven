import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepository(Supabase.instance.client),
);

class WishlistRepository {
  WishlistRepository(this._client);
  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  Future<bool> isWishlisted(String bookId) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _client
        .from('wishlist')
        .select('book_id')
        .eq('user_id', uid)
        .eq('book_id', bookId)
        .maybeSingle();
    return row != null;
  }

  /// Returns the new state (true = now in wishlist).
  Future<bool> toggle(String bookId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Please sign in first.');
    final exists = await isWishlisted(bookId);
    if (exists) {
      await _client
          .from('wishlist')
          .delete()
          .eq('user_id', uid)
          .eq('book_id', bookId);
      return false;
    }
    await _client.from('wishlist').insert({'user_id': uid, 'book_id': bookId});
    return true;
  }
}
