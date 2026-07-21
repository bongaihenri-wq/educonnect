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
      query = query.or(
          'first_name.ilike.%$searchQuery%,last_name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%');
    }

    final response = await query.order('days_inactive', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final response = await _supabase.from('payment_transactions').select("""
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
            parent:app_users!payment_transactions_parent_id_fkey(first_name, last_name, phone),
            schools!inner(name, country_code, payment_phone_number)
          """).eq('status', 'pending').order('created_at', ascending: false);

      final List<Map<String, dynamic>> result = [];

      for (final item in response) {
        final parent = item['parent'];
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
    await _supabase.from('payment_transactions').update({
      'status': 'rejected',
      'rejection_reason': reason,
    }).eq('id', transactionId);
  }

  // ✅ Status 'verified' utilisé dans la table payment_transactions
  Future<Map<String, dynamic>> getStats() async {
    try {
      final now = DateTime.now().toIso8601String();

      // 1. Parents en trial (actifs mais pas payé)
      final trialResponse = await _supabase
          .from('parent_subscriptions')
          .select('id')
          .eq('status', 'trial')
          .gte('trial_ends_at', now);

      final trialCount = (trialResponse as List).length;

      // 2. Parents en abonnement payant (actifs)
      final paidResponse = await _supabase
          .from('parent_subscriptions')
          .select('id')
          .eq('status', 'active')
          .gte('current_period_end', now);

      final paidCount = (paidResponse as List).length;

      // 3. Total parents actifs = trial + payant
      final totalActiveParents = trialCount + paidCount;

      // 4. Total des paiements validés (revenus réels)
      // ✅ Status 'verified' cohérent avec la fonction SQL validate_payment
      final revenueResponse = await _supabase
          .from('payment_transactions')
          .select('amount')
          .eq('status', 'verified');

      final totalRevenue = (revenueResponse as List).fold<int>(
          0, (sum, item) => sum + ((item['amount'] as num?)?.toInt() ?? 0));

      // 5. Revenus potentiels (si tous les trial convertissent)
      final potentialRevenue = totalActiveParents * 1000;

      // 6. Paiements en attente
      final pendingResponse = await _supabase
          .from('payment_transactions')
          .select('id')
          .eq('status', 'pending');

      final pendingCount = (pendingResponse as List).length;

      // 7. Abonnements expirés (trial fini + pas payé)
      final expiredResponse = await _supabase
          .from('parent_subscriptions')
          .select('id')
          .or('status.eq.expired,and(status.eq.trial,trial_ends_at.lt.$now)');

      final expiredCount = (expiredResponse as List).length;

      // 8. Total des parents (tous)
      final allParentsResponse =
          await _supabase.from('app_users').select('id').eq('role', 'parent');

      final totalParents = (allParentsResponse as List).length;

      final stats = {
        'total_parents': totalActiveParents,
        'totalParents': totalActiveParents,
        'active_parents': totalActiveParents,
        'trial_parents': trialCount,
        'paid_parents': paidCount,
        'monthly_revenue': totalRevenue,
        'monthlyRevenue': totalRevenue,
        'revenue': totalRevenue,
        'total_revenue': totalRevenue,
        'total_paid': totalRevenue,
        'potential_revenue': potentialRevenue,
        'pending_payments': pendingCount,
        'pendingPayments': pendingCount,
        'pending_count': pendingCount,
        'payments_pending': pendingCount,
        'expired_subscriptions': expiredCount,
        'expiredSubscriptions': expiredCount,
        'expired_count': expiredCount,
        'subscriptions_expired': expiredCount,
        'total_all_parents': totalParents,
      };

      print(
          '✅ STATS: trial=$trialCount, payant=$paidCount, actifs=$totalActiveParents, revenus=$totalRevenue, potentiel=$potentialRevenue');
      return stats;
    } catch (e) {
      print('❌ Erreur getStats: $e');
      return {
        'total_parents': 0,
        'totalParents': 0,
        'active_parents': 0,
        'trial_parents': 0,
        'paid_parents': 0,
        'monthly_revenue': 0,
        'monthlyRevenue': 0,
        'revenue': 0,
        'total_revenue': 0,
        'total_paid': 0,
        'potential_revenue': 0,
        'pending_payments': 0,
        'pendingPayments': 0,
        'pending_count': 0,
        'payments_pending': 0,
        'expired_subscriptions': 0,
        'expiredSubscriptions': 0,
        'expired_count': 0,
        'subscriptions_expired': 0,
        'total_all_parents': 0,
      };
    }
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
      query = query.or(
          'first_name.ilike.%$searchQuery%,last_name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%');
    }

    final response = await query.order('days_inactive', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getParentPaymentHistory(
      String parentId) async {
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
    var query = _supabase.from('payment_transactions').select(
        '*, parent:app_users!payment_transactions_parent_id_fkey(first_name, last_name, phone), school:schools!payment_transactions_school_id_fkey(name, country_code), validator:app_users!payment_transactions_verified_by_fkey(first_name, last_name)');

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
      query = query.or(
          'external_ref.ilike.%$searchQuery%,parent.first_name.ilike.%$searchQuery%,parent.last_name.ilike.%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> archivePayment(String transactionId) async {
    await _supabase.from('payment_transactions').update({
      'is_archived': true,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', transactionId);
  }

  // ============================================
  // ✅ NOUVEAU : Méthodes pour les numéros de paiement
  // ============================================

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
}
