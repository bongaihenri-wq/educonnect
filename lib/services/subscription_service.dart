// lib/services/subscription_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  final SupabaseClient _supabase;

  SubscriptionService(this._supabase);

  Future<List<Map<String, dynamic>>> getAllSubscriptions({
    String? schoolId,
    String? country,
    String? status,
    String? searchQuery,
  }) async {
    var query = _supabase.from('v_parents_to_relaunch').select();

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }
    if (country != null && country.isNotEmpty) {
      query = query.eq('school_country', country);
    }
    if (status != null && status.isNotEmpty) {
      query = query.eq('activity_status', status);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('first_name.ilike.%$searchQuery%,last_name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%');
    }

    final response = await query.order('days_inactive', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final response = await _supabase
          .from('payment_transactions')
          .select("""
            id,
            parent_id,
            school_id,
            external_ref,
            amount,
            currency,
            provider,
            status,
            depositor_phone,
            notes,
            created_at,
            app_users!inner(first_name, last_name, phone),
            schools!inner(name, country_code, payment_phone_number)
          """)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> result = [];
      
      for (final item in response) {
        final parent = item['app_users'] is List 
            ? (item['app_users'] as List).firstOrNull 
            : item['app_users'];
        final school = item['schools'] is List 
            ? (item['schools'] as List).firstOrNull 
            : item['schools'];

        result.add({
          'id': item['id'],
          'parent_id': item['parent_id'],
          'school_id': item['school_id'],
          'external_ref': item['external_ref'],
          'amount': item['amount'],
          'currency': item['currency'],
          'provider': item['provider'],
          'status': item['status'],
          'depositor_phone': item['depositor_phone'],
          'notes': item['notes'],
          'created_at': item['created_at'],
          'parent': parent,
          'school': school,
        });
      }

      return result;
    } catch (e) {
      print('Erreur getPendingPayments: $e');
      final fallback = await _supabase
          .from('payment_transactions')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(fallback);
    }
  }

  Future<Map<String, dynamic>> validatePayment({
    required String transactionId,
    required String adminId,
  }) async {
    final response = await _supabase.rpc(
      'validate_payment',
      params: {
        'p_transaction_id': transactionId,
        'p_admin_id': adminId,
      },
    );

    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first);
    } else if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw Exception('Format de reponse inattendu');
  }

  Future<void> rejectPayment({
    required String transactionId,
    required String reason,
  }) async {
    await _supabase
        .from('payment_transactions')
        .update({
          'status': 'rejected',
          'rejection_reason': reason,
        })
        .eq('id', transactionId);
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _supabase
          .from('v_subscription_summary')
          .select()
          .limit(1);

      if (response != null && response.isNotEmpty) {
        return Map<String, dynamic>.from(response[0]);
      }
    } catch (e) {
      print('Erreur getStats: $e');
    }
    
    return {
      'total_parents': 0,
      'active_subscriptions': 0,
      'trial_subscriptions': 0,
      'expired_subscriptions': 0,
      'pending_payments': 0,
      'monthly_revenue': 0,
    };
  }

  Future<List<Map<String, dynamic>>> getSchoolsForFilter() async {
    final response = await _supabase
        .from('schools')
        .select('id, name, country_code')
        .order('name');
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getParentsToRelaunch({
    String? schoolId,
    String? country,
    String? activityStatus,
    String? searchQuery,
  }) async {
    var query = _supabase.from('v_parents_to_relaunch').select();

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }
    if (country != null && country.isNotEmpty) {
      query = query.eq('school_country', country);
    }
    if (activityStatus != null && activityStatus.isNotEmpty) {
      query = query.eq('activity_status', activityStatus);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('first_name.ilike.%$searchQuery%,last_name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%');
    }

    final response = await query.order('days_inactive', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getParentPaymentHistory(String parentId) async {
    final response = await _supabase
        .from('payment_transactions')
        .select('*, school:schools!payment_transactions_school_id_fkey(name)')
        .eq('parent_id', parentId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory({
    String? status,
    String? schoolId,
    String? searchQuery,
    bool includeArchived = false,
  }) async {
    var query = _supabase
        .from('payment_transactions')
        .select('*, parent:app_users!payment_transactions_parent_id_fkey(first_name, last_name, phone), school:schools!payment_transactions_school_id_fkey(name, country_code), validator:app_users!payment_transactions_verified_by_fkey(first_name, last_name)');

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('external_ref.ilike.%$searchQuery%,parent.first_name.ilike.%$searchQuery%,parent.last_name.ilike.%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> archivePayment(String transactionId) async {
    await _supabase
        .from('payment_transactions')
        .update({'is_archived': true, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', transactionId);
  }
}