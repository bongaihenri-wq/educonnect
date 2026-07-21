// lib/services/payment_number_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentNumberService {
  final SupabaseClient _supabase;

  PaymentNumberService(this._supabase);

  /// Récupère les numéros de paiement pour un pays
  Future<List<Map<String, dynamic>>> getPaymentNumbersByCountry(
      String countryCode) async {
    final response = await _supabase.rpc(
      'get_payment_numbers_by_country',
      params: {'p_country_code': countryCode},
    );
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  /// Récupère le numéro principal pour un parent (via son école)
  Future<Map<String, dynamic>?> getParentPaymentInfo(String parentId) async {
    final response = await _supabase.rpc(
      'get_parent_payment_info',
      params: {'p_parent_id': parentId},
    );

    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first);
    }
    return null;
  }

  /// CRUD pour Super Admin
  Future<void> createPaymentNumber({
    required String countryCode,
    required String countryName,
    required String provider,
    required String phoneNumber,
    String? accountName,
    bool isPrimary = false,
    int monthlyAmount = 1000,
    String currency = 'XOF',
    String? adminId,
  }) async {
    await _supabase.from('payment_numbers').insert({
      'country_code': countryCode,
      'country_name': countryName,
      'provider': provider,
      'phone_number': phoneNumber,
      'account_name': accountName,
      'is_primary': isPrimary,
      'monthly_amount': monthlyAmount,
      'currency': currency,
      'created_by': adminId,
    });
  }

  Future<void> updatePaymentNumber({
    required String id,
    String? phoneNumber,
    String? accountName,
    bool? isActive,
    bool? isPrimary,
    int? monthlyAmount,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (accountName != null) updates['account_name'] = accountName;
    if (isActive != null) updates['is_active'] = isActive;
    if (isPrimary != null) updates['is_primary'] = isPrimary;
    if (monthlyAmount != null) updates['monthly_amount'] = monthlyAmount;

    await _supabase.from('payment_numbers').update(updates).eq('id', id);
  }

  Future<void> deletePaymentNumber(String id) async {
    await _supabase.from('payment_numbers').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getAllPaymentNumbers() async {
    final response = await _supabase
        .from('payment_numbers')
        .select()
        .order('country_code')
        .order('is_primary', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
