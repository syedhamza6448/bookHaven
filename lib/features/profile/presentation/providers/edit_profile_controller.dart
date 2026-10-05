import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/features/home/presentation/providers/home_providers.dart';
import 'package:bookhaven/features/profile/data/edit_profile_repository.dart';
import 'package:bookhaven/features/profile/presentation/providers/profile_providers.dart';

class EditProfileState {
  const EditProfileState({
    this.pickedBytes,
    this.removeAvatar = false,
    this.isSaving = false,
    this.error,
  });

  final Uint8List? pickedBytes;
  final bool removeAvatar;
  final bool isSaving;
  final String? error;

  EditProfileState copyWith({
    Uint8List? pickedBytes,
    bool clearPicked = false,
    bool? removeAvatar,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return EditProfileState(
      pickedBytes: clearPicked ? null : (pickedBytes ?? this.pickedBytes),
      removeAvatar: removeAvatar ?? this.removeAvatar,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EditProfileController extends Notifier<EditProfileState> {
  @override
  EditProfileState build() => const EditProfileState();

  Future<void> pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      state = state.copyWith(
        pickedBytes: bytes,
        removeAvatar: false,
        clearError: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('pick photo error: $e');
      state = state.copyWith(
        error: 'Could not open your photos. Please try again.',
      );
    }
  }

  void removePhoto() {
    state = state.copyWith(
      clearPicked: true,
      removeAvatar: true,
      clearError: true,
    );
  }

  Future<bool> save({required String fullName}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(editProfileRepositoryProvider);
    try {
      String? newUrl;
      if (state.pickedBytes != null) {
        newUrl = await repo.uploadAvatar(state.pickedBytes!);
      } else if (state.removeAvatar) {
        await repo.removeAvatarFile();
      }
      await repo.save(
        fullName: fullName,
        avatarUrl: newUrl,
        removeAvatar: state.removeAvatar,
      );
      ref.invalidate(profileProvider);
      ref.invalidate(userFirstNameProvider);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('save profile error: $e');
      final msg = e is StorageException
          ? 'Could not upload your photo. Check your connection and try again.'
          : 'Could not save your changes. Please try again.';
      state = state.copyWith(
        isSaving: false,
        error: kDebugMode ? '$msg\n$e' : msg,
      );
      return false;
    }
  }
}

final editProfileControllerProvider =
    NotifierProvider.autoDispose<EditProfileController, EditProfileState>(
      EditProfileController.new,
    );
