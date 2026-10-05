import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/shared/models/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

class ProfileRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<UserProfile> fetchProfile() async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('You are signed out.');

    final memberSince = DateTime.tryParse(user.createdAt)?.toLocal();

    final row = await _db
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      // Profile row missing: fall back to auth data
      final meta = user.userMetadata ?? {};
      return UserProfile.fromJson({
        'id': user.id,
        'email': user.email ?? '',
        'full_name': meta['full_name'] ?? meta['name'] ?? '',
        'role': 'user',
      }, memberSince: memberSince);
    }
    return UserProfile.fromJson(row, memberSince: memberSince);
  }

  Future<ProfileStats> fetchStats() async {
    final res = await _db.rpc('profile_stats');
    return ProfileStats.fromJson(Map<String, dynamic>.from(res as Map));
  }
}
