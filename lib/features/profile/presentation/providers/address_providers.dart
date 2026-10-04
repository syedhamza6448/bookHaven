import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookhaven/features/profile/data/address_repository.dart';
import 'package:bookhaven/shared/models/address.dart';

final addressesProvider = FutureProvider.autoDispose<List<Address>>(
  (ref) => ref.watch(addressRepositoryProvider).fetchAll(),
  retry: (_, __) => null,
);
