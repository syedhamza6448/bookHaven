import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrderSummary {
  const AdminOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.customer,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double total;
  final DateTime createdAt;
  final String customer;

  factory AdminOrderSummary.fromJson(Map<String, dynamic> j) =>
      AdminOrderSummary(
        id: j['id'] as String,
        orderNumber: j['order_number'] as String,
        status: j['status'] as String,
        total: (j['total'] as num).toDouble(),
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        customer: (j['customer'] as String?)?.trim().isNotEmpty == true
            ? j['customer'] as String
            : 'Customer',
      );
}

class AdminTopBook {
  const AdminTopBook({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.salesCount,
  });

  final String id;
  final String title;
  final String? coverUrl;
  final int salesCount;

  factory AdminTopBook.fromJson(Map<String, dynamic> j) => AdminTopBook(
    id: j['id'] as String,
    title: j['title'] as String,
    coverUrl: j['cover_url'] as String?,
    salesCount: (j['sales_count'] as num?)?.toInt() ?? 0,
  );
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.revenue,
    required this.ordersTotal,
    required this.ordersPending,
    required this.usersTotal,
    required this.booksTotal,
    required this.lowStock,
    required this.outOfStock,
    required this.recentOrders,
    required this.topBooks,
  });

  final double revenue;
  final int ordersTotal;
  final int ordersPending;
  final int usersTotal;
  final int booksTotal;
  final int lowStock;
  final int outOfStock;
  final List<AdminOrderSummary> recentOrders;
  final List<AdminTopBook> topBooks;

  factory AdminDashboardStats.fromJson(Map<String, dynamic> j) =>
      AdminDashboardStats(
        revenue: (j['revenue'] as num).toDouble(),
        ordersTotal: (j['orders_total'] as num).toInt(),
        ordersPending: (j['orders_pending'] as num).toInt(),
        usersTotal: (j['users_total'] as num).toInt(),
        booksTotal: (j['books_total'] as num).toInt(),
        lowStock: (j['low_stock'] as num).toInt(),
        outOfStock: (j['out_of_stock'] as num).toInt(),
        recentOrders: (j['recent_orders'] as List)
            .map((e) => AdminOrderSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        topBooks: (j['top_books'] as List)
            .map((e) => AdminTopBook.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AdminDashboardRepository {
  AdminDashboardRepository(this._client);
  final SupabaseClient _client;

  Future<AdminDashboardStats> fetchStats() async {
    final data = await _client.rpc('admin_dashboard_stats');
    return AdminDashboardStats.fromJson(Map<String, dynamic>.from(data as Map));
  }
}

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>(
  (ref) => AdminDashboardRepository(Supabase.instance.client),
);
