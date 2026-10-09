import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/features/admin/data/admin_book_editor_repository.dart';
import 'package:bookhaven/features/admin/data/admin_book_form.dart';

final adminBookEditorRepositoryProvider = Provider<AdminBookEditorRepository>(
  (ref) => AdminBookEditorRepository(Supabase.instance.client),
);

final adminBookFormProvider = FutureProvider.autoDispose
    .family<BookFormData, String>(
      (ref, id) => ref.read(adminBookEditorRepositoryProvider).fetchBook(id),
      retry: (retryCount, error) => null,
    );

final adminAuthorNamesProvider = FutureProvider.autoDispose<List<String>>(
  (ref) => ref.read(adminBookEditorRepositoryProvider).fetchAuthorNames(),
  retry: (retryCount, error) => null,
);

final adminGenreOptionsProvider = FutureProvider.autoDispose<List<GenreOption>>(
  (ref) => ref.read(adminBookEditorRepositoryProvider).fetchGenres(),
  retry: (retryCount, error) => null,
);
