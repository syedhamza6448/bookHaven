import 'package:intl/intl.dart';

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _int(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

String _str(dynamic v) => v == null ? '' : v.toString();

String? _strOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

class OrderItem {
  const OrderItem({
    required this.bookId,
    required this.title,
    required this.authorName,
    required this.coverUrl,
    required this.unitPrice,
    required this.quantity,
  });

  final String bookId;
  final String title;
  final String authorName;
  final String? coverUrl;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      bookId: _str(json['book_id']),
      title: _str(json['title']),
      authorName: _str(json['author_name']),
      coverUrl: _strOrNull(json['cover_url']),
      unitPrice: _num(json['unit_price']),
      quantity: _int(json['quantity'], 1),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.cardLast4,
    required this.createdAt,
    required this.shipFullName,
    required this.shipPhone,
    required this.shipLine1,
    required this.shipLine2,
    required this.shipCity,
    required this.shipState,
    required this.shipPostalCode,
    required this.shipCountry,
    required this.items,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String paymentMethod; // cod | card
  final String paymentStatus; // pending | paid
  final String? cardLast4;
  final DateTime createdAt;
  final String shipFullName;
  final String shipPhone;
  final String shipLine1;
  final String? shipLine2;
  final String shipCity;
  final String? shipState;
  final String shipPostalCode;
  final String shipCountry;
  final List<OrderItem> items;

  bool get isCod => paymentMethod == 'cod';
  bool get isPaid => paymentStatus == 'paid';
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  /// Delivery estimate: 3 to 5 days after the order was placed.
  DateTime get deliveryFrom => createdAt.add(const Duration(days: 3));
  DateTime get deliveryTo => createdAt.add(const Duration(days: 5));

  String get deliveryWindow {
    final f = DateFormat('EEE, d MMM');
    return '${f.format(deliveryFrom)} – ${f.format(deliveryTo)}';
  }

  /// Non-empty address lines, e.g. street / "Karachi, Sindh 75000" / country.
  List<String> get addressLines {
    final statePostal = [
      shipState ?? '',
      shipPostalCode,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');
    final cityLine = [
      shipCity.trim(),
      statePostal,
    ].where((e) => e.isNotEmpty).join(', ');
    return [
      shipLine1.trim(),
      (shipLine2 ?? '').trim(),
      cityLine,
      shipCountry.trim(),
    ].where((e) => e.isNotEmpty).toList();
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['order_items'] as List?) ?? const [];
    return Order(
      id: _str(json['id']),
      orderNumber: _str(json['order_number']),
      status: _str(json['status']).isEmpty ? 'placed' : _str(json['status']),
      subtotal: _num(json['subtotal']),
      deliveryFee: _num(json['delivery_fee']),
      total: _num(json['total']),
      paymentMethod: _str(json['payment_method']).isEmpty
          ? 'cod'
          : _str(json['payment_method']),
      paymentStatus: _str(json['payment_status']).isEmpty
          ? 'pending'
          : _str(json['payment_status']),
      cardLast4: _strOrNull(json['card_last4']),
      createdAt:
          DateTime.tryParse(_str(json['created_at']))?.toLocal() ??
          DateTime.now(),
      shipFullName: _str(json['ship_full_name']),
      shipPhone: _str(json['ship_phone']),
      shipLine1: _str(json['ship_line1']),
      shipLine2: _strOrNull(json['ship_line2']),
      shipCity: _str(json['ship_city']),
      shipState: _strOrNull(json['ship_state']),
      shipPostalCode: _str(json['ship_postal_code']),
      shipCountry: _str(json['ship_country']),
      items: rawItems
          .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
