import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/features/catalog/data/book_repository.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:bookhaven/shared/models/genre.dart';

// retry: null so errors show immediately instead of retrying in the background
final bestsellersProvider = FutureProvider.autoDispose<List<Book>>(
  (ref) => ref.read(bookRepositoryProvider).bestsellers(),
  retry: (retryCount, error) => null,
);

final newArrivalsProvider = FutureProvider.autoDispose<List<Book>>(
  (ref) => ref.read(bookRepositoryProvider).newArrivals(),
  retry: (retryCount, error) => null,
);

final featuredBookProvider = FutureProvider.autoDispose<Book?>(
  (ref) => ref.read(bookRepositoryProvider).featuredBook(),
  retry: (retryCount, error) => null,
);

final genresProvider = FutureProvider.autoDispose<List<Genre>>(
  (ref) => ref.read(bookRepositoryProvider).genres(),
  retry: (retryCount, error) => null,
);

final userFirstNameProvider = Provider.autoDispose<String>((ref) {
  try {
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
    final full = (meta?['full_name'] ?? meta?['name'] ?? '') as String;
    return full.trim().split(' ').first;
  } catch (_) {
    return '';
  }
});