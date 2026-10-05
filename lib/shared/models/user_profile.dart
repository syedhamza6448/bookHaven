class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.memberSince,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;
  final DateTime? memberSince;

  bool get isAdmin => role == 'admin';

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.first.isEmpty ? 'Reader' : parts.first;
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'B';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    DateTime? memberSince,
  }) {
    final email = (json['email' ?? ''].toString());
    final rawName = (json['full_name'] ?? '').toString().trim();
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      fullName: rawName.isNotEmpty ? rawName : email.split('@').first,
      email: email,
      role: (json['role'] ?? 'user').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      memberSince: memberSince,
    );
  }
}

class ProfileStats {
  const ProfileStats({
    required this.orders,
    required this.wishlist,
    required this.reviews,
  });

  final int orders;
  final int wishlist;
  final int reviews;

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return ProfileStats(
      orders: n(json['orders']),
      wishlist: n(json['wishlist']),
      reviews: n(json['reviews']),
    );
  }
}
