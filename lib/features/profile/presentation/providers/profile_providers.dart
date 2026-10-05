import 'package:bookhaven/features/profile/data/profile_repository.dart';
import 'package:bookhaven/shared/models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileProvider = FutureProvider.autoDispose<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).fetchProfile(),
  retry: (retryCount, error) => null,
);

final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>(
  (ref) => ref.watch(profileRepositoryProvider).fetchStats(),
  retry: (retryCount, error) => null,
);
