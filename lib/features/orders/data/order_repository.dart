import 'package:bookhaven/shared/models/order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(Supabase.instance.client);
});

class OrderRepository {
  OrderRepository(this._client);
  final SupabaseClient _client;

  /// Loads one order with its items. RLS only lets the owner (or an admin) read it.
  Future<Order> fetchOrder(String orderId) async {
    final data = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .single();
    return Order.fromJson(Map<String, dynamic>.from(data));
  }
}
