import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { signedOut, user, admin }

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  static const _redirectUrl = 'io.supabase.bookhaven://login-callback/';

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null; // Supabase not initialized (keys missing)
    }
  }

  Session? get currentSession => _client?.auth.currentSession;

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  /// Session first, then role from the profiles table.
  Future<AuthStatus> resolveStatus() async {
    final client = _client;
    if (client == null || client.auth.currentSession == null) {
      return AuthStatus.signedOut;
    }
    try {
      final userId = client.auth.currentUser!.id;
      final row = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      return row?['role'] == 'admin' ? AuthStatus.admin : AuthStatus.user;
    } catch (_) {
      return AuthStatus.user;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) throw Exception('Backend not configured.');
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Opens the Google sign-in in the browser; the result comes back through
  /// the deep link and is picked up by authStateChanges.
  Future<void> signInWithGoogle() async {
    final client = _client;
    if (client == null) throw Exception('Backend not configured.');
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectUrl,
    );
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }
}