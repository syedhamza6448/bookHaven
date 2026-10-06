import 'package:bookhaven/features/profile/data/saved_card_repository.dart';
import 'package:bookhaven/shared/models/saved_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final savedCardsProvider = FutureProvider.autoDispose<List<SavedCard>>(
  (ref) => ref.watch(savedCardRepositoryProvider).fetchAll(),
  retry: (retryCount, error) => null,
);
