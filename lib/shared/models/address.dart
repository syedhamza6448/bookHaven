class Address {
  const Address({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2,
    required this.city,
    this.state,
    required this.postalCode,
    required this.country,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String fullName;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String? state;
  final String postalCode;
  final String country;
  final bool isDefault;

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: j['id'] as String,
        label: (j['label'] as String?) ?? 'Home',
        fullName: j['full_name'] as String,
        phone: j['phone'] as String,
        line1: j['line1'] as String,
        line2: j['line2'] as String?,
        city: j['city'] as String,
        state: j['state'] as String?,
        postalCode: j['postal_code'] as String,
        country: (j['country'] as String?) ?? 'Pakistan',
        isDefault: (j['is_default'] as bool?) ?? false,
      );

  String get oneLine => [line1, line2, city, state, postalCode, country]
      .where((p) => p != null && p.trim().isNotEmpty)
      .join(', ');
}