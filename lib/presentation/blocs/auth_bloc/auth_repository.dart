// lib/presentation/blocs/auth_bloc/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // ─── Utilitaires ─────────────────────────────────────────────

  String? extractCountryCode(String phone) {
    if (phone.startsWith('+225')) return '+225';
    if (phone.startsWith('+237')) return '+237';
    if (phone.startsWith('+221')) return '+221';
    if (phone.startsWith('+233')) return '+233';
    if (phone.startsWith('+226')) return '+226';
    if (phone.startsWith('+241')) return '+241';
    return null;
  }

  // ─── Session / Prefs ───────────────────────────────────────

  Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user_id': prefs.getString('user_id'),
      'role': prefs.getString('role'),
      'school_id': prefs.getString('school_id'),
    };
  }

  Future<void> saveSession({
    required String userId,
    required String role,
    required String firstName,
    required String lastName,
    String? schoolId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('role', role);
    await prefs.setString('first_name', firstName);
    await prefs.setString('last_name', lastName);
    if (schoolId != null) {
      await prefs.setString('school_id', schoolId);
    } else {
      await prefs.remove('school_id');
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ─── Appels RPC / Auth ─────────────────────────────────────

  Future<List<dynamic>?> loginByPhone(String phone, String password) async {
    return await _supabase.rpc('login_by_phone', params: {
      'p_phone': phone,
      'p_password': password,
    });
  }

  // ─── Utilisateurs ──────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      return await _supabase
          .from('app_users')
          .select('id, first_name, last_name, role, school_id, email, phone')
          .eq('id', userId)
          .single();
    } catch (e) {
      print('Erreur getUserById: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSpecificRole(
    String userId,
    String phone,
    String? schoolId,
  ) async {
    try {
      final countryCode = extractCountryCode(phone);
      if (countryCode == null) return null;

      final response = await _supabase.rpc('get_role_for_user', params: {
        'p_user_id': userId,
        'p_country_code': countryCode,
        'p_school_id': schoolId,
      });

      if (response == null) return null;
      
      final data = response is List ? (response.isNotEmpty ? response[0] : null) : response;
      if (data == null) return null;

      return {
        'code': data['code']?.toString(),
        'name': data['name']?.toString(),
        'level': data['level'],
      };
    } catch (e) {
      print('Erreur role specifique: $e');
      return null;
    }
  }

  // ─── Écoles ────────────────────────────────────────────────

  Future<String> getSchoolName(String? schoolId) async {
    if (schoolId == null) return 'Toutes les ecoles';
    try {
      final school = await _supabase
          .from('schools')
          .select('name')
          .eq('id', schoolId)
          .single();
      return school?['name'] ?? 'Mon Ecole';
    } catch (e) {
      return 'Mon Ecole';
    }
  }

  Future<String?> getSchoolPaymentPhone(String? schoolId) async {
    if (schoolId == null) return null;
    try {
      final school = await _supabase
          .from('schools')
          .select('payment_phone_number')
          .eq('id', schoolId)
          .maybeSingle();
      return school?['payment_phone_number'];
    } catch (e) {
      print('Erreur recuperation ecole: $e');
      return null;
    }
  }

  // ─── Abonnements ───────────────────────────────────────────

  Future<Map<String, dynamic>?> checkSubscription(
    String parentId,
    String? schoolId,
  ) async {
    try {
      var response = await _supabase
          .from('parent_subscriptions')
          .select('id, status, plan_type, trial_ends_at, current_period_end, amount, currency')
          .eq('parent_id', parentId)
          .maybeSingle();

      // Création auto du trial si manquant
      if (response == null && schoolId != null) {
        print('Aucune subscription trouvée pour $parentId -> Création trial auto');
        try {
          await _supabase.from('parent_subscriptions').insert({
            'parent_id': parentId,
            'school_id': schoolId,
            'status': 'trial',
            'plan_type': 'trial',
            'trial_ends_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'amount': 1000,
            'currency': 'XOF',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('duplicate') || errorStr.contains('23505') || errorStr.contains('unique')) {
            print('Trial déjà existant (race condition), on continue');
          } else {
            print('Erreur création trial auto: $e');
          }
        }

        response = await _supabase
            .from('parent_subscriptions')
            .select('id, status, plan_type, trial_ends_at, current_period_end, amount, currency')
            .eq('parent_id', parentId)
            .maybeSingle();

        print('Trial auto créé/relu: $response');
      }

      if (response == null) return null;

      final paymentPhoneNumber = await getSchoolPaymentPhone(schoolId);

      final trialEndsAt = response['trial_ends_at'] != null
          ? DateTime.parse(response['trial_ends_at'])
          : null;
      final currentPeriodEnd = response['current_period_end'] != null
          ? DateTime.parse(response['current_period_end'])
          : null;
      final endDate = trialEndsAt ?? currentPeriodEnd;
      int? daysRemaining;
      if (endDate != null) {
        daysRemaining = endDate.difference(DateTime.now()).inDays;
      }

      return {
        'id': response['id'],
        'status': response['status'],
        'plan_type': response['plan_type'],
        'trial_ends_at': trialEndsAt,
        'current_period_end': currentPeriodEnd,
        'amount': response['amount'],
        'currency': response['currency'],
        'payment_phone_number': paymentPhoneNumber,
        'days_remaining': daysRemaining,
      };
    } catch (e) {
      print('Erreur verification abonnement: $e');
      return null;
    }
  }

  // ─── Paiements ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> checkPendingPayment(String parentId) async {
    try {
      final response = await _supabase
          .from('payment_transactions')
          .select('id, external_ref, amount, status, created_at, screenshot_url')
          .eq('parent_id', parentId)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return {
        'id': response['id'],
        'external_ref': response['external_ref'],
        'amount': (response['amount'] as num).toDouble(),
        'status': response['status'],
        'created_at': response['created_at'],
        'screenshot_url': response['screenshot_url'],
      };
    } catch (e) {
      print('Erreur verification paiement pending: $e');
      return null;
    }
  }

  Future<void> savePaymentTransaction({
    required String parentId,
    required String schoolId,
    required String reference,
    required double amount,
    String? phoneNumber,
    String? screenshotUrl,
  }) async {
    final existing = await _supabase
        .from('payment_transactions')
        .select('id')
        .eq('parent_id', parentId)
        .eq('status', 'pending')
        .maybeSingle();

    if (existing != null) {
      await _supabase.from('payment_transactions').update({
        'external_ref': reference,
        'amount': amount.toInt(),
        'depositor_phone': phoneNumber,
        'screenshot_url': screenshotUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', existing['id']);
    } else {
      await _supabase.from('payment_transactions').insert({
        'parent_id': parentId,
        'school_id': schoolId,
        'external_ref': reference,
        'amount': amount.toInt(),
        'currency': 'XOF',
        'provider': 'deposit',
        'status': 'pending',
        'depositor_phone': phoneNumber,
        'screenshot_url': screenshotUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ─── Données parent ────────────────────────────────────────

  Future<Map<String, dynamic>> getParentDataLite(
    String parentId,
    Map<String, dynamic>? sub,
  ) async {
    try {
      final parentStudent = await _supabase
          .from('parent_students')
          .select('student_id')
          .eq('parent_id', parentId)
          .single();
      
      Map<String, dynamic> studentData = {};
      if (parentStudent != null) {
        final student = await _supabase
            .from('students')
            .select('*, classes(name)')
            .eq('id', parentStudent['student_id'])
            .single();
        
        if (student != null) {
          studentData = {
            'studentId': student['id'],
            'studentName': '${student['first_name']} ${student['last_name']}',
            'studentMatricule': student['matricule'] ?? '',
            'className': student['classes']?['name'] ?? 'Classe inconnue',
          };
        }
      }

      String? status;
      DateTime? endDate;
      int? daysRemaining;
      int? amount;
      String? currency;
      String? paymentPhone;
      
      if (sub != null) {
        status = sub['status'] as String?;
        endDate = sub['trial_ends_at'] ?? sub['current_period_end'];
        amount = sub['amount'] as int?;
        currency = sub['currency'] as String?;
        paymentPhone = sub['payment_phone_number'] as String?;
        daysRemaining = sub['days_remaining'] as int?;
        
        if (daysRemaining != null && daysRemaining > 0 && daysRemaining <= 3) {
          status = 'expiring_soon';
        }
      } else {
        status = 'no_subscription';
        amount = 1000;
        currency = 'XOF';
      }

      return {
        ...studentData,
        'subscriptionStatus': status,
        'subscriptionEndDate': endDate,
        'daysRemaining': daysRemaining,
        'subscriptionAmount': amount ?? 1000,
        'subscriptionCurrency': currency ?? 'XOF',
        'paymentPhoneNumber': paymentPhone,
      };
    } catch (e) {
      print('Erreur recuperation parent data: $e');
      return {
        'subscriptionStatus': 'no_subscription',
        'subscriptionAmount': 1000,
        'subscriptionCurrency': 'XOF',
      };
    }
  }
}