import 'dart:math';

import 'package:bookhaven/features/cart/data/cart_items_repository.dart';
import 'package:bookhaven/shared/models/cart_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartController extends AsyncNotifier<List<CartItem>> {
  ({CartItem item, int index})? _lastRemoved;

  CartItemsRepository get _repo => ref.read(cartItemsRepositoryProvider);

  @override
  Future<List<CartItem>> build() => _repo.fetch();

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repo.fetch);
  }

  Future<void> setQuantity(String bookId, int quantity) async {
    final current = state.value;
    if (current == null) return;
    final index = current.indexWhere((i) => i.book.id == bookId);
    if (index < 0) return;

    final item = current[index];
    final max = item.book.stock < 1 ? 1 : item.book.stock;
    final next = quantity.clamp(1, max).toInt();
    if (next == item.quantity) return;

    final updated = [...current]..[index] = item.copyWith(quantity: next);
    state = AsyncData(updated);
    try {
      await _repo.setQuantity(bookId, next);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  Future<void> remove(String bookId) async {
    final current = state.value;
    if (current == null) return;
    final index = current.indexWhere((i) => i.book.id == bookId);
    if (index < 0) return;

    _lastRemoved = (item: current[index], index: index);
    state = AsyncData([...current]..removeAt(index));
    try {
      await _repo.remove(bookId);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  Future<void> undoRemove() async {
    final last = _lastRemoved;
    final current = state.value;
    if (last == null || current == null) return;
    _lastRemoved = null;

    final list = [...current]
      ..insert(min(last.index, current.length), last.item);
    state = AsyncData(list);
    try {
      await _repo.restore(last.item.book.id, last.item.quantity);
    } catch (_) {
      await refresh();
    }
  }

  Future<void> clear() async {
    state = const AsyncData([]);
    try {
      await _repo.clear();
    } catch (_) {
      await refresh();
    }
  }
}

final cartControllerProvider =
    AsyncNotifierProvider.autoDispose<CartController, List<CartItem>>(
      CartController.new,
      retry: (_, __) => null,
    );

final cartCountProvider = Provider.autoDispose<int>((ref) {
  final items = ref.watch(cartControllerProvider).value ?? const <CartItem>[];
  return CartTotals(items).itemCount;
});
