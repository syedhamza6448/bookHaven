import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => CheckoutRepository(),
);

class PlacedOrder {
  const PlacedOrder({required this.id, required this.orderNumber});
  final String id;
  final String orderNumber;
}

class CheckoutException implements Exception {
  CheckoutException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CheckoutRepository {
  Future<PlacedOrder> placeOrder({
    required String addressId,
    required String paymentMethod, // 'cod' or 'card'
    String? cardLast4,
  }) async {
    try {
      final res = await Supabase.instance.client.rpc(
        'place_order',
        params: {
          'p_address_id': addressId,
          'p_payment_method': paymentMethod,
          'p_card_last4': cardLast4,
        },
      );
      final map = Map<String, dynamic>.from(res as Map);
      return PlacedOrder(
        id: map['id'] as String,
        orderNumber: map['order_number'] as String,
      );
    } on PostgrestException catch (e) {
      throw CheckoutException(e.message);
    }
  }
}
