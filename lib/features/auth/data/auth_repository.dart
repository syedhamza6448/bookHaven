import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { signedOut, user, admin }

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Session? get currentSession => _client?.auth.currentSession;

  Future<AuthStatus> resolveStatus() async {
    final client = _client;
    final session = client?.auth.currentSession;
    if (client == null || session == null) return AuthStatus.signedOut;

    try {
      final profile = await client
          .from('profiles')
          .select('role')
          .eq('id', session.user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      return profile?['role'] == 'admin' ? AuthStatus.admin : AuthStatus.user;
    } catch (_) {
      return AuthStatus.user;
    }
  }
}
