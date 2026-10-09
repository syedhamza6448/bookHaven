import 'package:bookhaven/features/support/data/faq.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportException implements Exception {
  SupportException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SupportRepository {
  SupportRepository(this._client);
  final SupabaseClient _client;

  Future<List<Faq>> fetchFaqs() async {
    final List<dynamic> rows = await _client
        .from('faqs')
        .select()
        .eq('is_published', true)
        .order('sort_order');
    return rows
        .map((e) => Faq.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> submitRequest({
    required SupportTopic topic,
    required String subject,
    required String message,
    String? orderNumber,
  }) async {
    try {
      await _client.rpc(
        'submit_support_request',
        params: {
          'p_topic': topic.value,
          'p_subject': subject,
          'p_message': message,
          'p_order_number': orderNumber,
        },
      );
    } on PostgrestException catch (e) {
      throw SupportException(e.message);
    } catch (_) {
      throw SupportException(
        'Could not send your message. Check your connection and try again.',
      );
    }
  }
}

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepository(Supabase.instance.client),
);
