import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/shared/models/user_profile.dart';

const _headerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.lightPrimary, Color(0xFF14302A)],
);

const _headerRadius = BorderRadius.only(
  bottomLeft: Radius.circular(28),
  bottomRight: Radius.circular(28),
);

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final since = profile.memberSince;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: _headerGradient,
        borderRadius: _headerRadius,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 24,
        20,
        28,
      ),
      child: Column(
        children: [
          _Avatar(profile: profile),
          const SizedBox(height: 14),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: text.headlineMedium?.copyWith(color: AppColors.onPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: text.bodyMedium?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (profile.isAdmin) const _Pill(label: 'ADMIN', filled: true),
              if (since != null)
                _Pill(
                  label:
                      'MEMBER SINCE ${DateFormat('MMM yyyy').format(since).toUpperCase()}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl;
    final hasImage = url != null && url.isNotEmpty;

    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.darkAccent, width: 2),
      ),
      child: ClipOval(
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _Initials(initials: profile.initials),
              )
            : _Initials(initials: profile.initials),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkAccent.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.darkAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? AppColors.darkAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: filled
              ? AppColors.darkAccent
              : AppColors.onPrimary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: filled ? AppColors.lightPrimary : AppColors.onPrimary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: _headerGradient,
        borderRadius: _headerRadius,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 24,
        20,
        28,
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.12),
        highlightColor: Colors.white.withValues(alpha: 0.28),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 14),
            bar(170, 22),
            const SizedBox(height: 10),
            bar(200, 14),
            const SizedBox(height: 18),
            bar(130, 24),
          ],
        ),
      ),
    );
  }
}

class ProfileHeaderError extends StatelessWidget {
  const ProfileHeaderError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: _headerGradient,
        borderRadius: _headerRadius,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 40,
        20,
        32,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.darkAccent,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load your profile',
            style: text.titleMedium?.copyWith(color: AppColors.onPrimary),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkAccent,
              side: const BorderSide(color: AppColors.darkAccent),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
