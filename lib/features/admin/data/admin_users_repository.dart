import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_user.dart';

class AdminUserActionException implements Exception {
  const AdminUserActionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AdminUsersPage {
  const AdminUsersPage({
    required this.items,
    required this.total,
    required this.counts,
  });
  final List<AdminUser> items;
  final int total;
  final Map<String, int> counts;
}

class AdminUsersRepository {
  AdminUsersRepository() : _client = Supabase.instance.client;
  final SupabaseClient _client;

  static const pageSize = 15;

  Future<AdminUsersPage> fetchPage({
    required String query,
    required AdminUserFilter filter,
    required int offset,
  }) async {
    try {
      final res = await _client.rpc(
        'admin_list_users',
        params: {
          'p_query': query,
          'p_filter': filter.value,
          'p_limit': pageSize,
          'p_offset': offset,
        },
      );
      final map = Map<String, dynamic>.from(res as Map);
      final counts = <String, int>{};
      (map['counts'] as Map? ?? const {}).forEach((k, v) {
        counts['$k'] = (v as num).toInt();
      });
      return AdminUsersPage(
        items: ((map['items'] as List?) ?? const [])
            .map((e) => AdminUser.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        total: (map['total'] as num?)?.toInt() ?? 0,
        counts: counts,
      );
    } on PostgrestException catch (e) {
      throw AdminUserActionException(e.message);
    }
  }

  Future<AdminUserDetail> fetchDetail(String userId) async {
    try {
      final res = await _client.rpc(
        'admin_get_user',
        params: {'p_user_id': userId},
      );
      return AdminUserDetail.fromJson(Map<String, dynamic>.from(res as Map));
    } on PostgrestException catch (e) {
      throw AdminUserActionException(e.message);
    }
  }

  Future<void> setRole(String userId, String role) async {
    try {
      await _client.rpc(
        'admin_set_user_role',
        params: {'p_user_id': userId, 'p_role': role},
      );
    } on PostgrestException catch (e) {
      throw AdminUserActionException(e.message);
    }
  }
}

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>(
  (ref) => AdminUsersRepository(),
);
