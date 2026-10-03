import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryGenre {
  const CategoryGenre({
    required this.id,
    required this.name,
    required this.bookCount,
  });

  final String id;
  final String name;
  final int bookCount;

  factory CategoryGenre.fromJson(Map<String, dynamic> json) => CategoryGenre(
    id: json['id'].toString(),
    name: (json['name'] as String?) ?? '',
    bookCount: (json['book_count'] as num?)?.toInt() ?? 0,
  );
}

class CategoryAuthor {
  const CategoryAuthor({
    required this.id,
    required this.name,
    required this.bookCount,
  });

  final String id;
  final String name;
  final int bookCount;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory CategoryAuthor.fromJson(Map<String, dynamic> json) => CategoryAuthor(
    id: json['id'].toString(),
    name: (json['name'] as String?) ?? '',
    bookCount: (json['book_count'] as num?)?.toInt() ?? 0,
  );
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(),
);

class CategoryRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<CategoryGenre>> fetchGenres() async {
    final rows = await _db
        .from('genres_with_counts')
        .select('id, name, book_count')
        .order('name');
    return rows.map(CategoryGenre.fromJson).toList();
  }

  Future<List<CategoryAuthor>> fetchAuthors() async {
    final rows = await _db
        .from('authors_with_counts')
        .select('id, name, book_count')
        .order('name');
    return rows.map(CategoryAuthor.fromJson).toList();
  }
}
