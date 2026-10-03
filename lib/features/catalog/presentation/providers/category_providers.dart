import 'package:bookhaven/features/catalog/data/category_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryGenresProvider = FutureProvider.autoDispose<List<CategoryGenre>>(
  (ref) => ref.read(categoryRepositoryProvider).fetchGenres(),
  retry: (retryCount, error) => null,
);

final categoryAuthorsProvider =
    FutureProvider.autoDispose<List<CategoryAuthor>>(
      (ref) => ref.read(categoryRepositoryProvider).fetchAuthors(),
      retry: (retryCount, error) => null,
    );
