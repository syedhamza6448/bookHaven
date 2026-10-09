import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bookhaven/features/admin/data/admin_user.dart';
import 'package:bookhaven/features/admin/data/admin_users_repository.dart';

final adminUserDetailProvider = FutureProvider.autoDispose
    .family<AdminUserDetail, String>(
      (ref, userId) =>
          ref.read(adminUsersRepositoryProvider).fetchDetail(userId),
      retry: (count, error) => null,
    );
