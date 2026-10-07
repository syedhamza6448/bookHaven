class OrderStatusEvent {
  const OrderStatusEvent({
    required this.status,
    required this.createdAt,
    this.note,
  });

  final String status;
  final String? note;
  final DateTime createdAt;

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      status: (json['status'] ?? '').toString(),
      note: json['note']?.toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }
}
