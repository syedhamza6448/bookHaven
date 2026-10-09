import 'package:bookhaven/features/admin/data/admin_order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrdersPage {
  const AdminOrdersPage({
    required this.total,
    required this.items,
    required this.counts,
  });

  final int total;
  final List<AdminOrder> items;
  final Map<String, int> counts;
}

class AdminOrdersRepository {
  static const pageSize = 15;

  Future<AdminOrdersPage> fetchPage({
    required String query,
    required AdminOrderFilter filter,
    required int offset,
  }) async {
    final res = await Supabase.instance.client.rpc(
      'admin_list_orders',
      params: {
        'p_query': query,
        'p_filter': filter.value,
        'p_limit': pageSize,
        'p_offset': offset,
      },
    );

    final map = Map<String, dynamic>.from(res as Map);
    final items = (map['items'] as List)
        .map((e) => AdminOrder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final counts = <String, int>{
      for (final e in Map<String, dynamic>.from(map['counts'] as Map).entries)
        e.key: (e.value as num).toInt(),
    };

    return AdminOrdersPage(
      total: (map['total'] as num).toInt(),
      items: items,
      counts: counts,
    );
  }
}

final adminOrdersRepositoryProvider = Provider<AdminOrdersRepository>(
  (ref) => AdminOrdersRepository(),
);
