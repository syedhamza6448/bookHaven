enum AdminOrderFilter {
  all('all', 'All'),
  placed('placed', 'New'),
  processing('processing', 'Processing'),
  shipped('shipped', 'Shipped'),
  outForDelivery('out_for_delivery', 'Out for delivery'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled');

  const AdminOrderFilter(this.value, this.label);
  final String value;
  final String label;
}

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    required this.itemCount,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final String customerName;
  final String? customerEmail;
  final int itemCount;

  bool get isCod => paymentMethod == 'cod';
  bool get isPaid => paymentStatus == 'paid';

  static String statusLabel(String status) => switch (status) {
    'placed' => 'New',
    'processing' => 'Processing',
    'shipped' => 'Shipped',
    'out_for_delivery' => 'Out for delivery',
    'delivered' => 'Delivered',
    'cancelled' => 'Cancelled',
    _ => status,
  };

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: json['id'].toString(),
      orderNumber: (json['order_number'] ?? '').toString(),
      status: (json['status'] ?? 'placed').toString(),
      total: ((json['total'] ?? 0) as num).toDouble(),
      paymentMethod: (json['payment_method'] ?? 'cod').toString(),
      paymentStatus: (json['payment_status'] ?? 'pending').toString(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      customerName: (json['customer_name'] ?? 'Unknown customer').toString(),
      customerEmail: json['customer_email'] as String?,
      itemCount: ((json['item_count'] ?? 0) as num).toInt(),
    );
  }
}
