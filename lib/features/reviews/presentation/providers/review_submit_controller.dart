import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookhaven/features/catalog/presentation/providers/book_details_providers.dart';
import 'package:bookhaven/features/profile/presentation/providers/profile_providers.dart';
import 'package:bookhaven/features/reviews/data/my_review_repository.dart';

class ReviewSubmitState {
  const ReviewSubmitState({this.isSaving = false, this.error});

  final bool isSaving;
  final String? error;
}

class ReviewSubmitController extends Notifier<ReviewSubmitState> {
  ReviewSubmitController(this.bookId);

  final String bookId;

  @override
  ReviewSubmitState build() => const ReviewSubmitState();

  Future<bool> submit({required int rating, required String comment}) {
    return _run(
      () => ref
          .read(myReviewRepositoryProvider)
          .submit(bookId: bookId, rating: rating, comment: comment),
    );
  }

  Future<bool> delete() {
    return _run(() => ref.read(myReviewRepositoryProvider).delete(bookId));
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const ReviewSubmitState(isSaving: true);
    try {
      await action();
      if (!ref.mounted) return true;
      state = const ReviewSubmitState();
      _refreshRelated();
      return true;
    } on ReviewActionException catch (e) {
      if (ref.mounted) state = ReviewSubmitState(error: e.message);
      return false;
    } catch (e) {
      if (ref.mounted) {
        state = ReviewSubmitState(
          error: kDebugMode
              ? e.toString()
              : 'Something went wrong. Please try again.',
        );
      }
      return false;
    }
  }

  void _refreshRelated() {
    ref.invalidate(bookReviewsProvider); // reviews list on Book Details
    ref.invalidate(bookDetailsProvider); // updated rating average and count
    ref.invalidate(profileStatsProvider); // Reviews count on Profile
  }
}

final reviewSubmitControllerProvider = NotifierProvider.autoDispose
    .family<ReviewSubmitController, ReviewSubmitState, String>(
      ReviewSubmitController.new,
    );
