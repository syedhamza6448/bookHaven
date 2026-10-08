import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookhaven/features/reviews/data/my_review_repository.dart';

/// The current user's existing review for a book (null when they have none).
final myReviewProvider = FutureProvider.autoDispose.family<MyReview?, String>(
  (ref, bookId) => ref.read(myReviewRepositoryProvider).fetchMine(bookId),
  retry: (_, __) => null,
);
