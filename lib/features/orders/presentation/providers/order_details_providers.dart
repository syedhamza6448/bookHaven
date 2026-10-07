import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bookhaven/features/orders/data/order_details_repository.dart';
import 'package:bookhaven/shared/models/order_status_event.dart';

final orderStatusHistoryProvider = FutureProvider.autoDispose
    .family<List<OrderStatusEvent>, String>(
      (ref, orderId) =>
          ref.watch(orderDetailsRepositoryProvider).fetchHistory(orderId),
      retry: (_, __) => null,
    );
