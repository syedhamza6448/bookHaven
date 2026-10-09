import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/features/admin/data/admin_book.dart';

class AdminActionException implements Exception {
  AdminActionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AdminBooksPage {
  const AdminBooksPage({required this.items, required this.total});
  final List<AdminBook> items;
  final int total;
}

class AdminBooksRepository {
  AdminBooksRepository(this._client);
  final SupabaseClient _client;

  static const pageSize = 20;
  static const _bucket = 'book-covers';

  Future<AdminBooksPage> fetchPage({
    String query = '',
    AdminBookFilter filter = AdminBookFilter.all,
    int offset = 0,
  }) async {
    try {
      final res = await _client.rpc(
        'admin_list_books',
        params: {
          'p_query': query,
          'p_filter': filter.value,
          'p_limit': pageSize,
          'p_offset': offset,
        },
      );
      final map = Map<String, dynamic>.from(res as Map);
      final items = (map['items'] as List)
          .map((e) => AdminBook.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return AdminBooksPage(items: items, total: (map['total'] as num).toInt());
    } on PostgrestException catch (e) {
      throw AdminActionException(e.message);
    }
  }

  Future<void> deleteBook(AdminBook book) async {
    try {
      final cover = await _client.rpc(
        'admin_delete_book',
        params: {'p_book_id': book.id},
      );
      final path = _storagePath(cover as String?);
      if (path != null) {
        try {
          await _client.storage.from(_bucket).remove([path]);
        } catch (_) {
          // The book is already deleted; an orphaned file is harmless.
        }
      }
    } on PostgrestException catch (e) {
      throw AdminActionException(e.message);
    }
  }

  /// Only covers uploaded to our bucket have a path; seeded Open Library URLs return null.
  String? _storagePath(String? url) {
    if (url == null) return null;
    final marker = '/$_bucket/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    final raw = url.substring(idx + marker.length).split('?').first;
    return Uri.decodeComponent(raw);
  }
}

final adminBooksRepositoryProvider = Provider<AdminBooksRepository>(
  (ref) => AdminBooksRepository(Supabase.instance.client),
);
