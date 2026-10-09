import 'package:bookhaven/features/admin/data/admin_order_detail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrderActionException implements Exception {
  const AdminOrderActionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AdminOrderDetailRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<AdminOrderDetail> fetchDetail(String orderId) async {
    try {
      final res = await _db.rpc(
        'admin_get_order',
        params: {'p_order_id': orderId},
      );
      return AdminOrderDetail.fromJson(Map<String, dynamic>.from(res as Map));
    } on PostgrestException catch (e) {
      throw AdminOrderActionException(e.message);
    }
  }

  Future<void> updateStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    try {
      await _db.rpc(
        'admin_update_order_status',
        params: {
          'p_order_id': orderId,
          'p_status': status,
          'p_note': (note == null || note.trim().isEmpty) ? null : note.trim(),
        },
      );
    } on PostgrestException catch (e) {
      throw AdminOrderActionException(e.message);
    }
  }
}

final adminOrderDetailRepositoryProvider = Provider<AdminOrderDetailRepository>(
  (ref) => AdminOrderDetailRepository(),
);
