import 'package:bookhaven/shared/models/review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(Supabase.instance.client),
);

class ReviewRepository {
  ReviewRepository(this._client);
  final SupabaseClient _client;

  Future<List<Review>> fetchReviews(String bookId, {int limit = 30}) async {
    final rows = await _client
        .from('reviews')
        .select('*, review_likes(count)')
        .eq('book_id', bookId)
        .order('created_at', ascending: false)
        .limit(limit);

    final uid = _client.auth.currentUser?.id;
    var liked = <String>{};
    if (uid != null && rows.isNotEmpty) {
      final ids = rows.map((r) => r['id'].toString()).toList();
      final mine = await _client
          .from('review_likes')
          .select('review_id')
          .eq('user_id', uid)
          .inFilter('review_id', ids);
      liked = mine.map((r) => r['review_id'].toString()).toSet();
    }
    return rows
        .map(
          (r) =>
              Review.fromJson(r, likedByMe: liked.contains(r['id'].toString())),
        )
        .toList();
  }

  Future<void> setLike(String reviewId, {required bool like}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Please sign in first.');
    if (like) {
      await _client.from('review_likes').upsert({
        'review_id': reviewId,
        'user_id': uid,
      });
    } else {
      await _client
          .from('review_likes')
          .delete()
          .eq('review_id', reviewId)
          .eq('user_id', uid);
    }
  }
}
