import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final editProfileRepositoryProvider = Provider<EditProfileRepository>(
  (ref) => EditProfileRepository(),
);

class EditProfileRepository {
  static const _bucket = 'avatars';

  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Please sign in again.');
    return user.id;
  }

  /// Uploads to avatars/{uid}/avatar.jpg and returns a cache-busted public URL.
  Future<String> uploadAvatar(Uint8List bytes) async {
    final path = '$_userId/avatar.jpg';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    final url = _client.storage.from(_bucket).getPublicUrl(path);
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> removeAvatarFile() async {
    await _client.storage.from(_bucket).remove(['$_userId/avatar.jpg']);
  }

  Future<void> save({
    required String fullName,
    String? avatarUrl,
    bool removeAvatar = false,
  }) async {
    final name = fullName.trim();
    final updates = <String, dynamic>{'full_name': name};
    if (removeAvatar) {
      updates['avatar_url'] = null;
    } else if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }
    await _client.from('profiles').update(updates).eq('id', _userId);

    // Keep auth metadata in sync (Home greeting reads the name from here).
    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': name,
          if (removeAvatar)
            'avatar_url': null
          else if (avatarUrl != null)
            'avatar_url': avatarUrl,
        },
      ),
    );
  }
}
