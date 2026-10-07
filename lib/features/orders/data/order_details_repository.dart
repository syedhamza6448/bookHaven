import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/shared/models/order_status_event.dart';

final orderDetailsRepositoryProvider = Provider<OrderDetailsRepository>(
  (ref) => OrderDetailsRepository(),
);

class OrderActionException implements Exception {
  OrderActionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class OrderDetailsRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<OrderStatusEvent>> fetchHistory(String orderId) async {
    final rows = await _db
        .from('order_status_history')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: true);

    return (rows as List)
        .map(
          (e) => OrderStatusEvent.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _db.rpc('cancel_order', params: {'p_order_id': orderId});
    } on PostgrestException catch (e) {
      throw OrderActionException(e.message);
    }
  }

  /// Returns how many books were added to the cart.
  Future<int> reorder(String orderId) async {
    try {
      final res = await _db.rpc(
        'reorder_to_cart',
        params: {'p_order_id': orderId},
      );
      return (res as num?)?.toInt() ?? 0;
    } on PostgrestException catch (e) {
      throw OrderActionException(e.message);
    }
  }
}
