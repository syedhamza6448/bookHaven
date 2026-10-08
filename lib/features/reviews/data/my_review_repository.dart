import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyReview {
  const MyReview({
    required this.id,
    required this.rating,
    required this.comment,
  });

  final String id;
  final int rating;
  final String comment;
}

class ReviewActionException implements Exception {
  const ReviewActionException(this.message);
  final String message;

  @override
  String toString() => message;
}

final myReviewRepositoryProvider = Provider<MyReviewRepository>(
  (ref) => MyReviewRepository(),
);

class MyReviewRepository {
  SupabaseClient get _db => Supabase.instance.client;

  /// The signed-in user's review for this book, or null if none yet.
  Future<MyReview?> fetchMine(String bookId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;

    final row = await _db
        .from('reviews')
        .select('id, rating, comment')
        .eq('book_id', bookId)
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return null;

    return MyReview(
      id: row['id'].toString(),
      rating: (row['rating'] as num).toInt(),
      comment: (row['comment'] ?? '').toString(),
    );
  }

  Future<void> submit({
    required String bookId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _db.rpc(
        'submit_review',
        params: {'p_book_id': bookId, 'p_rating': rating, 'p_comment': comment},
      );
    } on PostgrestException catch (e) {
      throw ReviewActionException(_friendly(e));
    }
  }

  Future<void> delete(String bookId) async {
    try {
      await _db.rpc('delete_my_review', params: {'p_book_id': bookId});
    } on PostgrestException catch (e) {
      throw ReviewActionException(_friendly(e));
    }
  }

  String _friendly(PostgrestException e) {
    final msg = e.message;
    if (msg.contains('Not signed in')) {
      return 'Please sign in again to review this book.';
    }
    if (msg.contains('Book not found')) {
      return 'This book is no longer available.';
    }
    if (kDebugMode) return msg;
    return 'Could not save your review. Please try again.';
  }
}
