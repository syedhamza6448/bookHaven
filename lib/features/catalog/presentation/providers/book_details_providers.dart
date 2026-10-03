import 'package:bookhaven/features/catalog/data/book_details_repository.dart';
import 'package:bookhaven/features/reviews/data/review_repository.dart';
import 'package:bookhaven/features/wishlist/data/wishlist_repository.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:bookhaven/shared/models/review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookDetailsProvider = FutureProvider.autoDispose
    .family<BookDetails, String>(
      (ref, id) => ref.watch(bookDetailsRepositoryProvider).fetchBook(id),
      retry: (retryCount, error) => null,
    );

final relatedBooksProvider = FutureProvider.autoDispose
    .family<List<Book>, ({String bookId, String? genreId})>(
      (ref, args) => ref
          .watch(bookDetailsRepositoryProvider)
          .fetchRelated(bookId: args.bookId, genreId: args.genreId),
      retry: (retryCount, error) => null,
    );

final bookReviewsProvider = FutureProvider.autoDispose
    .family<List<Review>, String>(
      (ref, bookId) => ref.watch(reviewRepositoryProvider).fetchReviews(bookId),
      retry: (retryCount, error) => null,
    );

final isWishlistedProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, bookId) => ref.watch(wishlistRepositoryProvider).isWishlisted(bookId),
  retry: (retryCount, error) => null,
);
