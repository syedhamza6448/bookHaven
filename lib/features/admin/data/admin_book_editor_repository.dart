import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/features/admin/data/admin_book_form.dart';
import 'package:bookhaven/features/admin/data/admin_books_repository.dart';

class AdminBookEditorRepository {
  AdminBookEditorRepository(this._client);
  final SupabaseClient _client;

  static const _bucket = 'book-covers';

  Future<BookFormData> fetchBook(String id) async {
    try {
      final row = await _client
          .from('books')
          .select('*, authors(name)')
          .eq('id', id)
          .single();
      return BookFormData.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw AdminActionException(e.message);
    }
  }

  Future<List<String>> fetchAuthorNames() async {
    final rows = await _client.from('authors').select('name').order('name');
    return (rows as List).map((r) => (r as Map)['name'] as String).toList();
  }

  Future<List<GenreOption>> fetchGenres() async {
    final rows = await _client.from('genres').select('id, name').order('name');
    return (rows as List).map((r) {
      final m = r as Map;
      return GenreOption(id: m['id'].toString(), name: m['name'] as String);
    }).toList();
  }

  /// Uploads the picked image and returns its public URL.
  Future<String> uploadCover(Uint8List bytes, String ext) async {
    final path = 'covers/${DateTime.now().microsecondsSinceEpoch}.$ext';
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              cacheControl: '3600',
            ),
          );
      return _client.storage.from(_bucket).getPublicUrl(path);
    } on StorageException catch (e) {
      throw AdminActionException('Cover upload failed: ${e.message}');
    }
  }

  Future<String> saveBook({
    String? id,
    required String title,
    required String authorName,
    required String genreId,
    required String description,
    required double price,
    double? originalPrice,
    required int stock,
    required bool isFeatured,
    String? coverUrl,
    DateTime? publishedAt,
  }) async {
    try {
      final res = await _client.rpc(
        'admin_save_book',
        params: {
          'p_id': id,
          'p_title': title,
          'p_author_name': authorName,
          'p_genre_id': genreId,
          'p_description': description,
          'p_price': price,
          'p_original_price': originalPrice,
          'p_stock': stock,
          'p_is_featured': isFeatured,
          'p_cover_url': coverUrl,
          'p_published_at': publishedAt == null
              ? null
              : '${publishedAt.year.toString().padLeft(4, '0')}-'
                    '${publishedAt.month.toString().padLeft(2, '0')}-'
                    '${publishedAt.day.toString().padLeft(2, '0')}',
        },
      );
      return res as String;
    } on PostgrestException catch (e) {
      throw AdminActionException(e.message);
    }
  }

  /// Removes a cover from our bucket; URLs from elsewhere (Open Library) are ignored.
  Future<void> removeCoverFile(String? url) async {
    if (url == null) return;
    final marker = '/$_bucket/';
    final idx = url.indexOf(marker);
    if (idx == -1) return;
    final path = Uri.decodeComponent(
      url.substring(idx + marker.length).split('?').first,
    );
    try {
      await _client.storage.from(_bucket).remove([path]);
    } catch (_) {
      // An orphaned file is harmless.
    }
  }
}
