import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/features/profile/data/address_repository.dart';

extension AddressManagement on AddressRepository {
  SupabaseClient get _db => Supabase.instance.client;

  /// Inserts when [id] is null, otherwise updates that address.
  Future<void> saveAddress({
    String? id,
    required String label,
    required String fullName,
    required String phone,
    required String line1,
    String? line2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required bool isDefault,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('You are signed out. Please sign in again.');
    }

    final l2 = line2?.trim();
    final data = <String, dynamic>{
      'label': label.trim(),
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'line1': line1.trim(),
      'line2': (l2 == null || l2.isEmpty) ? null : l2,
      'city': city.trim(),
      'state': state.trim(),
      'postal_code': postalCode.trim(),
      'country': country.trim(),
    };

    String addressId;
    if (id == null) {
      final row = await _db
          .from('addresses')
          .insert({...data, 'user_id': uid, 'is_default': false})
          .select('id')
          .single();
      addressId = row['id'].toString();
    } else {
      await _db.from('addresses').update(data).eq('id', id);
      addressId = id;
    }

    if (isDefault) {
      await setDefaultAddress(addressId);
    }
  }

  Future<void> deleteAddress(String id) async {
    await _db.from('addresses').delete().eq('id', id);
  }

  Future<void> setDefaultAddress(String id) async {
    await _db.rpc('set_default_address', params: {'p_id': id});
  }
}
