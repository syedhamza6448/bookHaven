import 'package:bookhaven/features/admin/data/admin_dashboard_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardStats>(
  (ref) => ref.watch(adminDashboardRepositoryProvider).fetchStats(),
  retry: (retryCount, error) => null,
);
