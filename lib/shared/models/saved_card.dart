enum CardBrand {
  visa('Visa'),
  mastercard('Mastercard'),
  amex('American Express'),
  discover('Discover'),
  other('Card');

  const CardBrand(this.label);
  final String label;

  static CardBrand fromName(String? name) => CardBrand.values.firstWhere(
    (b) => b.name == name,
    orElse: () => CardBrand.other,
  );

  static CardBrand detect(String input) {
    final d = input.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return other;
    if (d.startsWith('4')) return visa;
    if (d.startsWith('34') || d.startsWith('37')) return amex;
    if (d.startsWith('6011') || d.startsWith('65')) return discover;
    if (d.length >= 2) {
      final two = int.parse(d.substring(0, 2));
      if (two >= 51 && two <= 55) return mastercard;
    }
    if (d.length >= 4) {
      final four = int.parse(d.substring(0, 4));
      if (four >= 2221 && four <= 2720) return mastercard;
    }
    return other;
  }
}

class SavedCard {
  const SavedCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.holderName,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
    required this.createdAt,
  });

  final String id;
  final CardBrand brand;
  final String last4;
  final String holderName;
  final int expMonth;
  final int expYear;
  final bool isDefault;
  final DateTime createdAt;

  bool get isExpired {
    final now = DateTime.now();
    return expYear < now.year || (expYear == now.year && expMonth < now.month);
  }

  String get expiryLabel =>
      '${expMonth.toString().padLeft(2, '0')}/${(expYear % 100).toString().padLeft(2, '0')}';

  String get maskedNumber => '••••  ••••  ••••  $last4';

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id'].toString(),
      brand: CardBrand.fromName(json['brand']?.toString()),
      last4: json['last4']?.toString() ?? '0000',
      holderName: json['holder_name']?.toString() ?? '',
      expMonth: (json['exp_month'] as num?)?.toInt() ?? 1,
      expYear: (json['exp_year'] as num?)?.toInt() ?? 2000,
      isDefault: json['is_default'] == true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
