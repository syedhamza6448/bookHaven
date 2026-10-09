enum AdminUserFilter {
  all('all', 'All'),
  user('user', 'Customers'),
  admin('admin', 'Admins');

  const AdminUserFilter(this.value, this.label);
  final String value;
  final String label;
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.createdAt,
    required this.orderCount,
    required this.totalSpent,
  });

  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;
  final int orderCount;
  final double totalSpent;

  bool get isAdmin => role == 'admin';

  String get displayName {
    final n = fullName.trim();
    if (n.isNotEmpty) return n;
    return email.contains('@') ? email.split('@').first : 'Reader';
  }

  String get initial => displayName.substring(0, 1).toUpperCase();

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
    id: j['id'] as String,
    fullName: (j['full_name'] as String?) ?? '',
    email: (j['email'] as String?) ?? '',
    avatarUrl: j['avatar_url'] as String?,
    role: (j['role'] as String?) ?? 'user',
    createdAt:
        DateTime.tryParse('${j['created_at']}')?.toLocal() ?? DateTime.now(),
    orderCount: (j['order_count'] as num?)?.toInt() ?? 0,
    totalSpent: (j['total_spent'] as num?)?.toDouble() ?? 0,
  );
}

class AdminUserOrder {
  const AdminUserOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double total;
  final DateTime createdAt;

  factory AdminUserOrder.fromJson(Map<String, dynamic> j) => AdminUserOrder(
    id: '${j['id']}',
    orderNumber: (j['order_number'] as String?) ?? '',
    status: (j['status'] as String?) ?? 'placed',
    total: (j['total'] as num?)?.toDouble() ?? 0,
    createdAt:
        DateTime.tryParse('${j['created_at']}')?.toLocal() ?? DateTime.now(),
  );
}

class AdminUserDetail {
  const AdminUserDetail({
    required this.user,
    required this.reviewsCount,
    required this.wishlistCount,
    required this.recentOrders,
  });

  final AdminUser user;
  final int reviewsCount;
  final int wishlistCount;
  final List<AdminUserOrder> recentOrders;

  factory AdminUserDetail.fromJson(Map<String, dynamic> j) => AdminUserDetail(
    user: AdminUser.fromJson(Map<String, dynamic>.from(j['user'] as Map)),
    reviewsCount: (j['reviews_count'] as num?)?.toInt() ?? 0,
    wishlistCount: (j['wishlist_count'] as num?)?.toInt() ?? 0,
    recentOrders: ((j['recent_orders'] as List?) ?? const [])
        .map(
          (e) => AdminUserOrder.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
  );
}
