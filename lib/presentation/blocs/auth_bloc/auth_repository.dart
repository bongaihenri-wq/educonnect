// lib/presentation/blocs/auth_bloc/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/logging/app_logger.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  final AppLogger _logger = AppLogger();

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
    final session = {
      'user_id': prefs.getString('user_id'),
      'role': prefs.getString('role'),
      'school_id': prefs.getString('school_id'),
    };

    _logger.logDebug(
      category: LogCategory.auth,
      message: 'Session récupérée',
      metadata: {
        'has_user_id': session['user_id'] != null,
        'role': session['role'],
      },
    );

    return session;
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

    // ✅ Mettre à jour le contexte du logger
    _logger.setUserContext(
      userId: userId,
      userRole: role,
      schoolId: schoolId,
    );

    _logger.logInfo(
      category: LogCategory.auth,
      message: 'Session sauvegardée',
      metadata: {
        'user_id': userId,
        'role': role,
        'school_id': schoolId,
      },
    );
  }

  Future<void> clearSession() async {
    try {
      await _supabase.auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      _logger.logWarning(
        category: LogCategory.auth,
        message: 'Erreur signOut local',
        errorCode: e.toString(),
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _logger.clearUserContext();
    _logger.logInfo(
      category: LogCategory.auth,
      message: 'Session effacée',
    );

    // Flush les logs avant logout
    await _logger.flush();
  }

  // ─── Appels RPC / Auth ─────────────────────────────────────

  Future<List<dynamic>?> loginByPhone(String phone, String password,
      {String? schoolCode}) async {
    final stopwatch = Stopwatch()..start();

    _logger.logInfo(
      category: LogCategory.auth,
      message: 'Tentative de connexion',
      metadata: {'phone': _anonymizePhone(phone)},
    );

    try {
      // ✅ NOUVEAU : le code école est transmis quand fourni → validation serveur
      final params = <String, dynamic>{
        'p_phone': phone,
        'p_password': password,
      };
      if (schoolCode != null) {
        params['p_school_code'] = schoolCode.trim();
      }

      final response = await _supabase.rpc('login_by_phone', params: params);

      stopwatch.stop();

      if (response == null || response.isEmpty) {
        _logger.logError(
          category: LogCategory.auth,
          message: 'Réponse vide de login_by_phone',
          apiEndpoint: 'login_by_phone',
        );
        return null;
      }

      final result = response[0];

      if (result['success'] == true) {
        _logger.logApi(
          endpoint: 'login_by_phone',
          method: 'RPC',
          statusCode: 200,
          durationMs: stopwatch.elapsedMilliseconds,
        );

        _logger.logAnalytics(
          eventName: 'login_success',
          parameters: {
            'role': result['role'],
            'phone': _anonymizePhone(phone),
          },
        );
      } else {
        _logger.logWarning(
          category: LogCategory.auth,
          message: 'Échec connexion: ${result['message']}',
          metadata: {
            'reason': result['message'],
            'phone': _anonymizePhone(phone),
          },
        );
      }

      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();

      _logger.logError(
        category: LogCategory.auth,
        message: 'Erreur login_by_phone',
        error: e,
        stackTrace: stackTrace,
        apiEndpoint: 'login_by_phone',
        metadata: {'duration_ms': stopwatch.elapsedMilliseconds},
      );

      rethrow;
    }
  }

  // ─── Utilisateurs ──────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final stopwatch = Stopwatch()..start();

    try {
      final user = await _supabase
          .from('app_users')
          .select(
              'id, first_name, last_name, role, school_id, email, phone, country_code')
          .eq('id', userId)
          .single();

      stopwatch.stop();

      _logger.logApi(
        endpoint: 'app_users/select',
        method: 'GET',
        statusCode: user != null ? 200 : 404,
        durationMs: stopwatch.elapsedMilliseconds,
      );

      return user;
    } catch (e, stackTrace) {
      stopwatch.stop();

      _logger.logError(
        category: LogCategory.api,
        message: 'Erreur getUserById',
        error: e,
        stackTrace: stackTrace,
      );

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
      if (countryCode == null) {
        _logger.logWarning(
          category: LogCategory.auth,
          message: 'Code pays non extrait',
          metadata: {'phone': _anonymizePhone(phone)},
        );
        return null;
      }

      final response = await _supabase.rpc('get_role_for_user', params: {
        'p_user_id': userId,
        'p_country_code': countryCode,
        'p_school_id': schoolId,
      });

      if (response == null) return null;

      final data = response is List
          ? (response.isNotEmpty ? response[0] : null)
          : response;
      if (data == null) return null;

      _logger.logInfo(
        category: LogCategory.auth,
        message: 'Rôle spécifique récupéré',
        metadata: {'role_code': data['code']},
      );

      return {
        'code': data['code']?.toString(),
        'name': data['name']?.toString(),
        'level': data['level'],
      };
    } catch (e, stackTrace) {
      _logger.logError(
        category: LogCategory.auth,
        message: 'Erreur getSpecificRole',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // ─── Écoles ────────────────────────────────────────────────

  Future<String> getSchoolName(String? schoolId) async {
    if (schoolId == null) {
      _logger.logDebug(
        category: LogCategory.api,
        message: 'getSchoolName: school_id null',
      );
      return 'Toutes les ecoles';
    }
    try {
      final school = await _supabase
          .from('schools')
          .select('name')
          .eq('id', schoolId)
          .single();

      return school?['name'] ?? 'Mon Ecole';
    } catch (e, stackTrace) {
      _logger.logError(
        category: LogCategory.api,
        message: 'Erreur getSchoolName',
        error: e,
        stackTrace: stackTrace,
      );
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
      _logger.logError(
        category: LogCategory.api,
        message: 'Erreur getSchoolPaymentPhone',
        error: e,
      );
      return null;
    }
  }

  /// ✅ NOUVEAU : Infos de facturation de l'école (source de vérité du montant)
  Future<Map<String, dynamic>?> getSchoolBillingInfo(String? schoolId) async {
    if (schoolId == null) return null;
    try {
      final school = await _supabase
          .from('schools')
          .select('monthly_fee, currency, payment_phone_number')
          .eq('id', schoolId)
          .maybeSingle();
      return school;
    } catch (e) {
      _logger.logError(
        category: LogCategory.api,
        message: 'Erreur getSchoolBillingInfo',
        error: e,
      );
      return null;
    }
  }

  // ─── Abonnements ───────────────────────────────────────────

  Future<Map<String, dynamic>?> checkSubscription(
    String parentId,
    String? schoolId,
  ) async {
    try {
      // ✅ NOUVEAU : frais de l'école = source de vérité du montant affiché
      final billing = await getSchoolBillingInfo(schoolId);
      final schoolFee = (billing?['monthly_fee'] as num?)?.toInt() ?? 0;
      final schoolCurrency = billing?['currency'] as String?;

      var response = await _supabase
          .from('parent_subscriptions')
          .select(
              'id, status, plan_type, trial_ends_at, current_period_end, amount, currency')
          .eq('parent_id', parentId)
          .maybeSingle();

      if (response == null && schoolId != null) {
        _logger.logInfo(
          category: LogCategory.business,
          message: 'Création trial auto',
          metadata: {'parent_id': parentId},
        );

        try {
          await _supabase.from('parent_subscriptions').insert({
            'parent_id': parentId,
            'school_id': schoolId,
            'status': 'trial',
            'plan_type': 'trial',
            'trial_ends_at':
                DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'amount': schoolFee > 0 ? schoolFee : 1000, // ✅ CORRIGÉ
            'currency': schoolCurrency ?? 'XOF', // ✅ CORRIGÉ
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('duplicate') ||
              errorStr.contains('23505') ||
              errorStr.contains('unique')) {
            _logger.logDebug(
              category: LogCategory.business,
              message: 'Trial déjà existant (race condition)',
            );
          } else {
            _logger.logError(
              category: LogCategory.business,
              message: 'Erreur création trial auto',
              error: e,
            );
          }
        }

        response = await _supabase
            .from('parent_subscriptions')
            .select(
                'id, status, plan_type, trial_ends_at, current_period_end, amount, currency')
            .eq('parent_id', parentId)
            .maybeSingle();
      }

      if (response == null) return null;

      // ✅ CORRIGÉ : le téléphone vient du même fetch (1 requête économisée)
      final paymentPhoneNumber = billing?['payment_phone_number'] as String?;

      final trialEndsAt = response['trial_ends_at'] != null
          ? DateTime.parse(response['trial_ends_at'])
          : null;
      final currentPeriodEnd = response['current_period_end'] != null
          ? DateTime.parse(response['current_period_end'])
          : null;
      final endDate = response['status'] == 'active'
          ? (currentPeriodEnd ?? trialEndsAt)
          : (trialEndsAt ?? currentPeriodEnd);
      int? daysRemaining;
      if (endDate != null) {
        daysRemaining = endDate.difference(DateTime.now()).inDays;
      }

      _logger.logInfo(
        category: LogCategory.business,
        message: 'Abonnement vérifié',
        metadata: {
          'status': response['status'],
          'days_remaining': daysRemaining,
        },
      );

      return {
        'id': response['id'],
        'status': response['status'],
        'plan_type': response['plan_type'],
        'trial_ends_at': trialEndsAt,
        'current_period_end': currentPeriodEnd,
        // ✅ CORRIGÉ : frais école en priorité, sinon montant stocké, sinon 1000
        'amount': schoolFee > 0 ? schoolFee : (response['amount'] ?? 1000),
        'currency': schoolCurrency ?? response['currency'] ?? 'XOF',
        'payment_phone_number': paymentPhoneNumber,
        'days_remaining': daysRemaining,
      };
    } catch (e, stackTrace) {
      _logger.logError(
        category: LogCategory.business,
        message: 'Erreur vérification abonnement',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // ─── Paiements ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> checkPendingPayment(String parentId) async {
    try {
      final response = await _supabase
          .from('payment_transactions')
          .select(
              'id, external_ref, amount, status, created_at, screenshot_url')
          .eq('parent_id', parentId)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _logger.logInfo(
          category: LogCategory.business,
          message: 'Paiement pending trouvé',
          metadata: {
            'reference': response['external_ref'],
            'amount': response['amount'],
          },
        );
      }

      return response == null
          ? null
          : {
              'id': response['id'],
              'external_ref': response['external_ref'],
              'amount': (response['amount'] as num).toDouble(),
              'status': response['status'],
              'created_at': response['created_at'],
              'screenshot_url': response['screenshot_url'],
            };
    } catch (e, stackTrace) {
      _logger.logError(
        category: LogCategory.business,
        message: 'Erreur vérification paiement pending',
        error: e,
        stackTrace: stackTrace,
      );
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
    _logger.logInfo(
      category: LogCategory.business,
      message: 'Sauvegarde paiement',
      metadata: {
        'reference': reference,
        'amount': amount,
      },
    );

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

      _logger.logInfo(
        category: LogCategory.business,
        message: 'Paiement mis à jour',
      );
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

      _logger.logInfo(
        category: LogCategory.business,
        message: 'Nouveau paiement créé',
      );
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

      _logger.logInfo(
        category: LogCategory.auth,
        message: 'Données parent récupérées',
        metadata: {
          'has_student': studentData.isNotEmpty,
          'subscription_status': status,
        },
      );

      return {
        ...studentData,
        'subscriptionStatus': status,
        'subscriptionEndDate': endDate,
        'daysRemaining': daysRemaining,
        'subscriptionAmount': amount ?? 1000,
        'subscriptionCurrency': currency ?? 'XOF',
        'paymentPhoneNumber': paymentPhone,
      };
    } catch (e, stackTrace) {
      _logger.logError(
        category: LogCategory.auth,
        message: 'Erreur récupération parent data',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'subscriptionStatus': 'no_subscription',
        'subscriptionAmount': 1000,
        'subscriptionCurrency': 'XOF',
      };
    }
  }

  // ─── Helper ────────────────────────────────────────────────

  String _anonymizePhone(String phone) {
    if (phone.length < 4) return '***';
    return '${phone.substring(0, 2)}****${phone.substring(phone.length - 2)}';
  }
}
