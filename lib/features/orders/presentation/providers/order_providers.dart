import 'package:bookhaven/features/orders/data/order_repository.dart';
import 'package:bookhaven/shared/models/order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final orderProvider = FutureProvider.autoDispose.family<Order, String>(
  (ref, orderId) => ref.read(orderRepositoryProvider).fetchOrder(orderId),
  retry: (count, error) => null,
);
