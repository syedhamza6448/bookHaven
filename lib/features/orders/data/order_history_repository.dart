import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/features/orders/data/order_filter.dart';
import 'package:bookhaven/shared/models/order.dart';

final orderHistoryRepositoryProvider = Provider<OrderHistoryRepository>(
  (ref) => OrderHistoryRepository(),
);

class OrderHistoryRepository {
  static const pageSize = 10;

  Future<List<Order>> fetchPage({
    required OrderFilter filter,
    required int page,
  }) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('You need to be signed in to see your orders.');
    }

    var query = client
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', uid);

    final statuses = filter.statuses;
    if (statuses != null) {
      query = query.inFilter('status', statuses);
    }

    final from = page * pageSize;
    final rows = await query
        .order('created_at', ascending: false)
        .range(from, from + pageSize - 1);

    return (rows as List)
        .map((r) => Order.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }
}
