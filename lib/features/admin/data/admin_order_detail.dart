import 'package:bookhaven/shared/models/order.dart';

class AdminOrderLine {
  const AdminOrderLine({
    required this.title,
    required this.authorName,
    required this.coverUrl,
    required this.unitPrice,
    required this.quantity,
  });

  final String title;
  final String authorName;
  final String? coverUrl;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  factory AdminOrderLine.fromJson(Map<String, dynamic> j) => AdminOrderLine(
    title: (j['title'] ?? '').toString(),
    authorName: (j['author_name'] ?? '').toString(),
    coverUrl: j['cover_url'] as String?,
    unitPrice: ((j['unit_price'] ?? 0) as num).toDouble(),
    quantity: ((j['quantity'] ?? 1) as num).toInt(),
  );
}

class AdminStatusEvent {
  const AdminStatusEvent({
    required this.status,
    required this.note,
    required this.createdAt,
  });

  final String status;
  final String? note;
  final DateTime createdAt;

  factory AdminStatusEvent.fromJson(Map<String, dynamic> j) => AdminStatusEvent(
    status: (j['status'] ?? '').toString(),
    note: j['note'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
  );
}

class AdminOrderDetail {
  const AdminOrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.cardLast4,
    required this.total,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    required this.customerAvatarUrl,
    required this.lines,
    required this.addressLines,
    required this.history,
  });

  static const flow = [
    'placed',
    'processing',
    'shipped',
    'out_for_delivery',
    'delivered',
  ];

  final String id;
  final String orderNumber;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String? cardLast4;
  final double total;
  final DateTime createdAt;
  final String customerName;
  final String? customerEmail;
  final String? customerAvatarUrl;
  final List<AdminOrderLine> lines;
  final List<String> addressLines;
  final List<AdminStatusEvent> history; // newest first

  bool get isCod => paymentMethod == 'cod';
  bool get isPaid => paymentStatus == 'paid';
  bool get isTerminal => status == 'delivered' || status == 'cancelled';

  double get subtotal => lines.fold(0.0, (sum, l) => sum + l.lineTotal);
  double get deliveryFee => (total - subtotal) < 0 ? 0 : total - subtotal;
  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  /// Statuses the order can still move to (forward only).
  List<String> get nextStatuses {
    if (isTerminal) return const [];
    final i = flow.indexOf(status);
    return i < 0 ? const [] : flow.sublist(i + 1);
  }

  factory AdminOrderDetail.fromJson(Map<String, dynamic> map) {
    final o = Map<String, dynamic>.from(map['order'] as Map);
    final customer = Map<String, dynamic>.from(map['customer'] as Map);
    final order = Order.fromJson(o); // reused only for the address lines

    return AdminOrderDetail(
      id: o['id'].toString(),
      orderNumber: (o['order_number'] ?? '').toString(),
      status: (o['status'] ?? 'placed').toString(),
      paymentMethod: (o['payment_method'] ?? 'cod').toString(),
      paymentStatus: (o['payment_status'] ?? 'pending').toString(),
      cardLast4: o['card_last4'] as String?,
      total: ((o['total'] ?? 0) as num).toDouble(),
      createdAt: DateTime.parse(o['created_at'] as String).toLocal(),
      customerName: (customer['name'] ?? 'Unknown customer').toString(),
      customerEmail: customer['email'] as String?,
      customerAvatarUrl: customer['avatar_url'] as String?,
      lines: (o['order_items'] as List)
          .map(
            (e) => AdminOrderLine.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      addressLines: order.addressLines.map((e) => e.toString()).toList(),
      history: (map['history'] as List)
          .map(
            (e) =>
                AdminStatusEvent.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}
