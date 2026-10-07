import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bookhaven/features/orders/data/order_filter.dart';
import 'package:bookhaven/features/orders/data/order_history_repository.dart';
import 'package:bookhaven/shared/models/order.dart';

class OrderHistoryState {
  const OrderHistoryState({
    this.orders = const [],
    this.filter = OrderFilter.all,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.loadMoreError,
  });

  final List<Order> orders;
  final OrderFilter filter;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? loadMoreError;

  OrderHistoryState copyWith({
    List<Order>? orders,
    OrderFilter? filter,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? loadMoreError,
    bool clearError = false,
    bool clearLoadMoreError = false,
  }) {
    return OrderHistoryState(
      orders: orders ?? this.orders,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }
}

class OrderHistoryController extends Notifier<OrderHistoryState> {
  int _page = 0;
  int _token = 0; // ignores stale responses when the filter changes quickly

  @override
  OrderHistoryState build() {
    Future.microtask(() {
      if (ref.mounted) _loadFirst(OrderFilter.all);
    });
    return const OrderHistoryState();
  }

  Future<void> refresh() => _loadFirst(state.filter, silent: true);

  Future<void> setFilter(OrderFilter filter) async {
    if (filter == state.filter) return;
    await _loadFirst(filter);
  }

  Future<void> _loadFirst(OrderFilter filter, {bool silent = false}) async {
    final token = ++_token;
    _page = 0;
    state = state.copyWith(
      filter: filter,
      orders: silent ? state.orders : const [],
      isLoading: !silent,
      isLoadingMore: false,
      hasMore: true,
      clearError: true,
      clearLoadMoreError: true,
    );

    try {
      final page = await ref
          .read(orderHistoryRepositoryProvider)
          .fetchPage(filter: filter, page: 0);
      if (!ref.mounted || token != _token) return;
      _page = 1;
      state = state.copyWith(
        orders: page,
        isLoading: false,
        hasMore: page.length == OrderHistoryRepository.pageSize,
      );
    } catch (e) {
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(
        isLoading: false,
        // On a silent pull-to-refresh failure keep showing the old list.
        error: state.orders.isEmpty ? _message(e) : null,
      );
    }
  }

  Future<void> loadMore({bool retry = false}) async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    // After a failure, only an explicit retry tries again (stops scroll loops).
    if (state.loadMoreError != null && !retry) return;

    final token = _token;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);

    try {
      final next = await ref
          .read(orderHistoryRepositoryProvider)
          .fetchPage(filter: state.filter, page: _page);
      if (!ref.mounted || token != _token) return;
      _page++;
      state = state.copyWith(
        orders: [...state.orders, ...next],
        isLoadingMore: false,
        hasMore: next.length == OrderHistoryRepository.pageSize,
      );
    } catch (e) {
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(isLoadingMore: false, loadMoreError: _message(e));
    }
  }

  String _message(Object e) => kDebugMode
      ? e.toString()
      : 'We could not load your orders. Please try again.';
}

final orderHistoryControllerProvider =
    NotifierProvider.autoDispose<OrderHistoryController, OrderHistoryState>(
      OrderHistoryController.new,
    );
