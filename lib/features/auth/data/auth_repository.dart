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

  Future<AuthResponse> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) {
    return Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
      emailRedirectTo: 'io.supabase.bookhaven://login-callback/',
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

  Future<void> sendPasswordResetCode(String email) {
    return Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
  }

  Future<AuthResponse> verifyPasswordResetCode({
    required String email,
    required String code,
  }) {
    return Supabase.instance.client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email.trim(),
      token: code.trim(),
    );
  }

  Future<UserResponse> updatePassword(String newPassword) {
    return Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
