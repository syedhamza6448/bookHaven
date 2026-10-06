import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bookhaven/features/cart/presentation/providers/cart_controller.dart';
import 'package:bookhaven/features/profile/presentation/providers/profile_providers.dart';
import 'package:bookhaven/features/wishlist/data/wishlist_items_repository.dart';
import 'package:bookhaven/shared/models/book.dart';

class WishlistController extends AsyncNotifier<List<Book>> {
  WishlistItemsRepository get _repo => ref.read(wishlistItemsRepositoryProvider);

  @override
  Future<List<Book>> build() => ref.watch(wishlistItemsRepositoryProvider).fetchAll();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Removes a book optimistically. Returns the index it had (for undo),
  /// or null if it was not in the list. Rolls back and rethrows on failure.
  Future<int?> remove(Book book) async {
    final current = state.value;
    if (current == null) return null;
    final index = current.indexWhere((b) => b.id == book.id);
    if (index < 0) return null;

    state = AsyncData([...current]..removeAt(index));
    try {
      await _repo.remove(book.id);
      ref.invalidate(profileStatsProvider);
      return index;
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> restore(Book book, int index) async {
    final current = state.value ?? <Book>[];
    if (current.any((b) => b.id == book.id)) return;

    final at = index.clamp(0, current.length);
    state = AsyncData([...current]..insert(at, book));
    try {
      await _repo.restore(book.id);
      ref.invalidate(profileStatsProvider);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Not optimistic: the server checks stock first.
  Future<void> moveToCart(Book book) async {
    await _repo.moveToCart(book.id);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.where((b) => b.id != book.id).toList());
    }
    ref.invalidate(cartControllerProvider);
    ref.invalidate(profileStatsProvider);
  }
}

final wishlistControllerProvider =
    AsyncNotifierProvider.autoDispose<WishlistController, List<Book>>(
  WishlistController.new,
  retry: (retryCount, error) => null,
);

final wishlistCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(wishlistControllerProvider).value?.length ?? 0,
);