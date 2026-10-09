import 'package:bookhaven/features/support/data/faq.dart';
import 'package:bookhaven/features/support/data/support_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final faqsProvider = FutureProvider.autoDispose<List<Faq>>(
  (ref) => ref.watch(supportRepositoryProvider).fetchFaqs(),
  retry: (retryCount, error) => null,
);
