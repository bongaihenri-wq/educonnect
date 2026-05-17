// lib/presentation/blocs/auth_bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient _supabase;

  AuthBloc(this._supabase) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginWithPhoneRequested>(_onLoginWithPhone);
    on<PaymentReferenceSubmitted>(_onPaymentReferenceSubmitted);
    on<LogoutRequested>(_onLogout);
  }

  // ============================================================
  // 🔥 VÉRIFICATION ABONNEMENT PARENT
  // ============================================================
  
  Future<Map<String, dynamic>?> _checkSubscription(
    String parentId,
    String? schoolId,
  ) async {
    try {
      final response = await _supabase
          .from('parent_subscriptions')
          .select('''
            id,
            status,
            plan_type,
            trial_ends_at,
            current_period_end,
            amount,
            currency
          ''')
          .eq('parent_id', parentId)
          .maybeSingle();

      if (response == null) return null;

      String? paymentPhoneNumber;
      if (schoolId != null) {
        try {
          final school = await _supabase
              .from('schools')
              .select('payment_phone_number')
              .eq('id', schoolId)
              .maybeSingle();
          paymentPhoneNumber = school?['payment_phone_number'];
        } catch (e) {
          print('⚠️ Erreur récupération école: $e');
        }
      }

      return {
        'id': response['id'],
        'status': response['status'],
        'plan_type': response['plan_type'],
        'trial_ends_at': response['trial_ends_at'] != null
            ? DateTime.parse(response['trial_ends_at'])
            : null,
        'current_period_end': response['current_period_end'] != null
            ? DateTime.parse(response['current_period_end'])
            : null,
        'amount': response['amount'],
        'currency': response['currency'],
        'payment_phone_number': paymentPhoneNumber,
      };
    } catch (e) {
      print('❌ Erreur vérification abonnement: $e');
      return null;
    }
  }

  // ============================================================
  // ⭐ VÉRIFICATION PAIEMENT PENDING
  // ============================================================
  
  Future<Map<String, dynamic>?> _checkPendingPayment(String parentId) async {
    try {
      final response = await _supabase
          .from('payment_transactions')
          .select('id, external_ref, amount, status, created_at')
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
      };
    } catch (e) {
      print('❌ Erreur vérification paiement pending: $e');
      return null;
    }
  }

  bool _isSubscriptionExpired(Map<String, dynamic>? sub) {
    if (sub == null) {
      print('🔴 SUBSCRIPTION NULL → CONSIDÉRÉ COMME EXPIRÉ');
      return true;
    }
    
    final status = sub['status'] as String?;
    if (status == null) {
      print('🔴 STATUT NULL → CONSIDÉRÉ COMME EXPIRÉ');
      return true;
    }

    print('🟡 Statut trouvé: $status');

    if (status == 'expired') {
      print('🔴 STATUT = expired');
      return true;
    }

    if (status == 'trial') {
      final trialEndsAt = sub['trial_ends_at'] as DateTime?;
      if (trialEndsAt != null && DateTime.now().isAfter(trialEndsAt)) {
        print('🔴 TRIAL EXPIRÉ: $trialEndsAt');
        return true;
      }
      print('🟢 TRIAL EN COURS jusquà $trialEndsAt');
    }

    if (status == 'active') {
      final currentPeriodEnd = sub['current_period_end'] as DateTime?;
      if (currentPeriodEnd != null && DateTime.now().isAfter(currentPeriodEnd)) {
        print('🔴 ACTIF EXPIRÉ: $currentPeriodEnd');
        return true;
      }
      print('🟢 ACTIF jusquà $currentPeriodEnd');
    }

    if (status != 'trial' && status != 'active') {
      print('🔴 STATUT INCONNU: $status → EXPIRÉ');
      return true;
    }

    return false;
  }

  // ============================================================
  // HANDLERS
  // ============================================================

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final role = prefs.getString('role');
      
      if (userId != null && role != null) {
        final user = await _supabase
            .from('app_users')
            .select('id, first_name, last_name, role, school_id, email, phone')
            .eq('id', userId)
            .single();
        
        if (role == 'parent') {
          print('🔍 [AppStarted] Vérification abonnement pour parent: $userId');
          final sub = await _checkSubscription(userId, user['school_id']);
          print('🔍 [AppStarted] Subscription: $sub');
          
          final pendingPayment = await _checkPendingPayment(userId);
          print('🔍 [AppStarted] Paiement pending: $pendingPayment');
          
          if (pendingPayment != null) {
            print('🟡 [AppStarted] PAIEMENT PENDING → PaymentPendingPage');
            emit(PaymentSubmittedSuccessfully(
              parentId: userId,
              reference: pendingPayment['external_ref'],
              amount: pendingPayment['amount'],
              submittedAt: DateTime.parse(pendingPayment['created_at']),
            ));
            return;
          }
          
          if (_isSubscriptionExpired(sub)) {
            print('🔴 [AppStarted] ABONNEMENT EXPIRÉ → SubscriptionExpired');
            emit(SubscriptionExpired(
              parentId: userId,
              schoolId: user['school_id'],
              expiresAt: sub?['trial_ends_at'] ?? sub?['current_period_end'],
              amount: sub?['amount'] ?? 1000,
              currency: sub?['currency'] ?? 'XOF',
              paymentPhoneNumber: sub?['payment_phone_number'],
            ));
            return;
          }
          print('🟢 [AppStarted] Abonnement OK');
        }
        
        final schoolName = await _getSchoolName(user['school_id']);
        
        Map<String, dynamic> parentData = {};
        if (role == 'parent') {
          parentData = await _getParentData(userId);
        }
        
        _emitAuthenticated(user, schoolName, emit, parentData: parentData);
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      print('❌ [AppStarted] Erreur: $e');
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginWithPhone(
    LoginWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    print('🔍 AUTHBLOC PHONE RECU: "${event.phone}"');
    
    try {
      final response = await _supabase.rpc('login_by_phone', params: {
        'p_phone': event.phone,
        'p_password': event.password,
      });

      if (response == null || response.isEmpty) {
        emit(AuthError('Erreur serveur'));
        return;
      }

      final result = response[0];
      
      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', result['user_id']);
        await prefs.setString('role', result['role']);
        await prefs.setString('first_name', result['first_name']);
        await prefs.setString('last_name', result['last_name']);
        
        final schoolId = result['school_id'] as String?;
        if (schoolId != null) {
          await prefs.setString('school_id', schoolId);
        } else {
          await prefs.remove('school_id');
        }
        
        if (result['role'] == 'parent') {
          print('🔍 [Login] Vérification abonnement pour parent: ${result['user_id']}');
          final sub = await _checkSubscription(result['user_id'], schoolId);
          print('🔍 [Login] Subscription: $sub');
          
          final pendingPayment = await _checkPendingPayment(result['user_id']);
          print('🔍 [Login] Paiement pending: $pendingPayment');
          
          if (pendingPayment != null) {
            print('🟡 [Login] PAIEMENT PENDING → PaymentPendingPage');
            emit(PaymentSubmittedSuccessfully(
              parentId: result['user_id'],
              reference: pendingPayment['external_ref'],
              amount: pendingPayment['amount'],
              submittedAt: DateTime.parse(pendingPayment['created_at']),
            ));
            return;
          }
          
          if (_isSubscriptionExpired(sub)) {
            print('🔴 [Login] ABONNEMENT EXPIRÉ → SubscriptionExpired');
            emit(SubscriptionExpired(
              parentId: result['user_id'],
              schoolId: schoolId,
              expiresAt: sub?['trial_ends_at'] ?? sub?['current_period_end'],
              amount: sub?['amount'] ?? 1000,
              currency: sub?['currency'] ?? 'XOF',
              paymentPhoneNumber: sub?['payment_phone_number'],
            ));
            return;
          }
          print('🟢 [Login] Abonnement OK');
        }
        
        final schoolName = await _getSchoolName(schoolId);
        
        Map<String, dynamic> parentData = {};
        if (result['role'] == 'parent') {
          parentData = await _getParentData(result['user_id']);
        }
        
        _emitAuthenticated({
          'id': result['user_id'],
          'first_name': result['first_name'],
          'last_name': result['last_name'],
          'role': result['role'],
          'school_id': schoolId,
          'email': result['email'],
          'phone': result['phone'],
        }, schoolName, emit, parentData: parentData);
      } else {
        emit(AuthError(result['message']));
      }
    } catch (e) {
      print('❌ [Login] Erreur: $e');
      emit(AuthError('Erreur de connexion: $e'));
    }
  }

  // ✅ CORRIGÉ : Ajout schoolId + gestion propre
  Future<void> _onPaymentReferenceSubmitted(
    PaymentReferenceSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // ⭐ CORRIGÉ : Ajout school_id obligatoire
      await _supabase.from('payment_transactions').insert({
        'parent_id': event.parentId,
        'school_id': event.schoolId, // ⭐ AJOUTÉ
        'external_ref': event.reference,
        'amount': event.amount.toInt(),
        'currency': 'XOF',
        'provider': 'wave',
        'status': 'pending',
        'notes': event.phoneNumber,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Paiement inséré: ${event.reference}');

      // ✅ CORRIGÉ : Recharger ParentAuthenticated au lieu de bloquer
      final user = await _supabase
          .from('app_users')
          .select('id, first_name, last_name, role, school_id, email, phone')
          .eq('id', event.parentId)
          .single();

      final schoolName = await _getSchoolName(user['school_id']);
      final parentData = await _getParentData(event.parentId);

      _emitAuthenticated(user, schoolName, emit, parentData: parentData);
      
    } catch (e) {
      print('❌ Erreur paiement: $e');
      emit(AuthError('Erreur lors de la soumission: $e'));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    emit(Unauthenticated());
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<String> _getSchoolName(String? schoolId) async {
    if (schoolId == null) return 'Toutes les écoles';
    try {
      final school = await _supabase
          .from('schools')
          .select('name')
          .eq('id', schoolId)
          .single();
      return school?['name'] ?? 'Mon École';
    } catch (e) {
      return 'Mon École';
    }
  }

  Future<Map<String, dynamic>> _getParentData(String parentId) async {
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

      final sub = await _checkSubscription(parentId, studentData.isNotEmpty ? null : null);
      
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
        
        if (endDate != null) {
          daysRemaining = endDate.difference(DateTime.now()).inDays;
        }
      } else {
        status = 'no_subscription';
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
      print('❌ Erreur récupération parent data: $e');
      return {
        'subscriptionStatus': 'no_subscription',
        'subscriptionAmount': 1000,
        'subscriptionCurrency': 'XOF',
      };
    }
  }

  void _emitAuthenticated(
    Map<String, dynamic> user,
    String schoolName,
    Emitter<AuthState> emit, {
    Map<String, dynamic> parentData = const {},
  }) {
    final role = user['role'];
    
    if (role == 'super_admin') {
      emit(SuperAdminAuthenticated(
        userId: user['id'],
        firstName: user['first_name'],
        lastName: user['last_name'],
        email: user['email'] ?? '',
        phone: user['phone'] ?? '',
      ));
    } else if (role == 'admin') {
      emit(AdminAuthenticated(
        userId: user['id'],
        firstName: user['first_name'],
        lastName: user['last_name'],
        schoolId: user['school_id'] ?? '',
        schoolName: schoolName,
      ));
    } else if (role == 'teacher') {
      emit(TeacherAuthenticated(
        userId: user['id'],
        firstName: user['first_name'],
        lastName: user['last_name'],
        schoolId: user['school_id'] ?? '',
        schoolName: schoolName,
      ));
    } else if (role == 'parent') {
      emit(ParentAuthenticated(
        userId: user['id'],
        firstName: user['first_name'],
        lastName: user['last_name'],
        schoolId: user['school_id'] ?? '',
        schoolName: schoolName,
        studentId: parentData['studentId'] ?? '',
        studentName: parentData['studentName'] ?? '',
        studentMatricule: parentData['studentMatricule'] ?? '',
        className: parentData['className'] ?? '',
        subscriptionStatus: parentData['subscriptionStatus'],
        subscriptionEndDate: parentData['subscriptionEndDate'],
        daysRemaining: parentData['daysRemaining'],
        subscriptionAmount: parentData['subscriptionAmount'],
        subscriptionCurrency: parentData['subscriptionCurrency'],
        paymentPhoneNumber: parentData['paymentPhoneNumber'],
      ));
    } else {
      emit(AuthError('Rôle inconnu: $role'));
    }
  }
}