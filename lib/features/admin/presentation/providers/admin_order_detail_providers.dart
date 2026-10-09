import 'package:bookhaven/features/admin/data/admin_order_detail.dart';
import 'package:bookhaven/features/admin/data/admin_order_detail_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminOrderDetailProvider = FutureProvider.autoDispose
    .family<AdminOrderDetail, String>(
      (ref, orderId) =>
          ref.read(adminOrderDetailRepositoryProvider).fetchDetail(orderId),
      retry: (_, __) => null,
    );
