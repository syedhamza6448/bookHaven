import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/validators.dart';
import 'package:bookhaven/features/profile/presentation/providers/edit_profile_controller.dart';
import 'package:bookhaven/features/profile/presentation/providers/profile_providers.dart';
import 'package:bookhaven/shared/models/user_profile.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: profile.when(
        skipLoadingOnReload: true,
        data: (p) => _EditProfileForm(profile: p),
        loading: () => const _Fallback(child: CircularProgressIndicator()),
        error: (e, _) => _Fallback(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load your profile.',
                style: TextStyle(color: c.textSecondary),
              ),
              TextButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          const Align(alignment: Alignment.topLeft, child: BackButton()),
          Center(child: child),
        ],
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.fullName);
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(editProfileControllerProvider.notifier)
        .save(fullName: _name.text);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
      context.pop();
    }
  }

  Future<bool> _confirmDiscard() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  void _showPhotoSheet(bool hasPhoto) {
    final c = context.palette;
    final notifier = ref.read(editProfileControllerProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusCard),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppDimens.sm),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                notifier.pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                notifier.pick(ImageSource.camera);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: Icon(Icons.delete_outline, color: c.error),
                title: Text('Remove photo', style: TextStyle(color: c.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  notifier.removePhoto();
                },
              ),
            const SizedBox(height: AppDimens.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final s = ref.watch(editProfileControllerProvider);
    final p = widget.profile;

    final url = p.avatarUrl ?? '';
    final hasPhoto =
        s.pickedBytes != null || (!s.removeAvatar && url.isNotEmpty);
    final dirty =
        s.pickedBytes != null ||
        s.removeAvatar ||
        _name.text.trim() != p.fullName;

    ImageProvider? image;
    if (s.pickedBytes != null) {
      image = MemoryImage(s.pickedBytes!);
    } else if (!s.removeAvatar && url.isNotEmpty) {
      image = CachedNetworkImageProvider(url);
    }

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) context.pop();
      },
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.primary,
                  Color.alphaBlend(
                    Colors.black.withValues(alpha: 0.28),
                    c.primary,
                  ),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.onPrimary,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      Text(
                        'Edit profile',
                        style: text.titleLarge?.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.sm),
                  GestureDetector(
                        onTap: () => _showPhotoSheet(hasPhoto),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: c.accent, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: c.surface,
                                backgroundImage: image,
                                child: image == null
                                    ? Text(
                                        p.initials,
                                        style: text.headlineMedium?.copyWith(
                                          color: c.primary,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: c.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: c.primary,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(begin: const Offset(0.92, 0.92), duration: 300.ms),
                  const SizedBox(height: AppDimens.sm),
                  TextButton(
                    onPressed: () => _showPhotoSheet(hasPhoto),
                    child: Text(
                      'Change photo',
                      style: TextStyle(color: c.accent),
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                ],
              ),
            ),
          ),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                children: [
                  Text(
                    'FULL NAME',
                    style: text.labelMedium?.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    validator: Validators.fullName,
                    decoration: const InputDecoration(
                      hintText: 'Your name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppDimens.xl),
                  Text(
                    'EMAIL',
                    style: text.labelMedium?.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  TextFormField(
                    initialValue: p.email,
                    enabled: false,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: AppDimens.xs),
                  Text(
                    'Your email is used to sign in and cannot be changed here.',
                    style: text.bodySmall?.copyWith(color: c.textSecondary),
                  ),
                  if (s.error != null) ...[
                    const SizedBox(height: AppDimens.lg),
                    Container(
                      padding: const EdgeInsets.all(AppDimens.md),
                      decoration: BoxDecoration(
                        color: c.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusInput,
                        ),
                        border: Border.all(
                          color: c.error.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        s.error!,
                        style: text.bodySmall?.copyWith(color: c.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimens.xxl),
                  SizedBox(
                    height: AppDimens.buttonHeight,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: dirty && !s.isSaving ? _save : null,
                      child: s.isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('Save changes'),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03),
            ),
          ),
        ],
      ),
    );
  }
}
