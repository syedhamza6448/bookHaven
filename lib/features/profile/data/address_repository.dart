import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bookhaven/shared/models/address.dart';

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(),
);

class AddressRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Address>> fetchAll() async {
    final rows = await _db
        .from('addresses')
        .select()
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return rows.map((e) => Address.fromJson(e)).toList();
  }

  Future<Address> add({
    required String label,
    required String fullName,
    required String phone,
    required String line1,
    String? line2,
    required String city,
    String? state,
    required String postalCode,
    required String country,
    required bool isDefault,
  }) async {
    final uid = _db.auth.currentUser!.id;
    final row = await _db
        .from('addresses')
        .insert({
          'user_id': uid,
          'label': label,
          'full_name': fullName,
          'phone': phone,
          'line1': line1,
          'line2': (line2 == null || line2.trim().isEmpty)
              ? null
              : line2.trim(),
          'city': city,
          'state': (state == null || state.trim().isEmpty)
              ? null
              : state.trim(),
          'postal_code': postalCode,
          'country': country,
          'is_default': isDefault,
        })
        .select()
        .single();
    return Address.fromJson(row);
  }
}
