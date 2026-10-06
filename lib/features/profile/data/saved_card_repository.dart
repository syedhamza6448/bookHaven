import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/shared/models/saved_card.dart';

final savedCardRepositoryProvider = Provider<SavedCardRepository>(
  (ref) => SavedCardRepository(),
);

class SavedCardRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<SavedCard>> fetchAll() async {
    final rows = await _db
        .from('saved_cards')
        .select()
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return rows
        .map<SavedCard>((r) => SavedCard.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Only the brand and last 4 digits are extracted and sent.
  /// The full number never leaves this method.
  Future<void> add({
    required String cardNumber,
    required String holderName,
    required int expMonth,
    required int expYear,
    required bool makeDefault,
  }) async {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    await _db.from('saved_cards').insert({
      'brand': CardBrand.detect(digits).name,
      'last4': digits.substring(digits.length - 4),
      'holder_name': holderName.trim(),
      'exp_month': expMonth,
      'exp_year': expYear,
      'is_default': makeDefault,
    });
  }

  Future<void> setDefault(String id) async {
    await _db.from('saved_cards').update({'is_default': true}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _db.from('saved_cards').delete().eq('id', id);
  }
}
