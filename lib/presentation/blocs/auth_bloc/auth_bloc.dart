// lib/presentation/blocs/auth_bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(SupabaseClient supabase) 
      : _repository = AuthRepository(supabase),
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginWithPhoneRequested>(_onLoginWithPhone);
    on<PaymentReferenceSubmitted>(_onPaymentReferenceSubmitted);
    on<CheckSubscriptionStatusRequested>(_onCheckSubscriptionStatus);
    on<LogoutRequested>(_onLogout);
  }

  // ─── Logique métier pure ───────────────────────────────────

  bool _isSubscriptionExpired(Map<String, dynamic>? sub) {
    if (sub == null) {
      print('SUBSCRIPTION NULL -> NOUVEAU PARENT (pas expire)');
      return false;
    }
    
    final status = sub['status'] as String?;
    final daysRemaining = sub['days_remaining'] as int?;
    
    if (status == null) {
      print('STATUT NULL -> EXPIRE');
      return true;
    }

    print('Statut trouve: $status, jours restants: $daysRemaining');

    if (status == 'expired') {
      print('STATUT = expired');
      return true;
    }

    if (daysRemaining != null && daysRemaining <= 0) {
      print('TOTALLY EXPIRED: $daysRemaining jours');
      return true;
    }

    if (daysRemaining != null && daysRemaining > 0 && daysRemaining <= 3) {
      print('EXPIRING SOON: $daysRemaining jours -> ACCES AUTORISE');
      return false;
    }

    if (status == 'trial' || status == 'active') {
      print('ABONNEMENT OK');
      return false;
    }

    print('STATUT INCONNU: $status -> EXPIRE');
    return true;
  }

  // ✅ CORRIGÉ : countryCode assistant depuis user + ajout principal
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
    } else if (role == 'assistant') {
      emit(AssistantAuthenticated(
        userId: user['id'],
        firstName: user['first_name'],
        lastName: user['last_name'],
        schoolId: user['school_id'] ?? '',
        schoolName: schoolName,
        countryCode: user['country_code'] ?? '', // ✅ CORRIGÉ : depuis user
      ));
    } else if (role == 'principal') { // ✅ AJOUTÉ : cas principal manquant
      emit(PrincipalAuthenticated(
        userId: user['id'],
        firstName: user['first_name'],
        lastName: user['last_name'],
        schoolId: user['school_id'] ?? '',
        schoolName: schoolName,
        classId: '',
        className: '',
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
      emit(AuthError('Role inconnu: $role'));
    }
  }

  // ─── Helpers ───────────────────────────────────────────────

  // ✅ Parser DateTime proprement depuis Supabase (String -> DateTime)
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // ─── Handlers ──────────────────────────────────────────────

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final session = await _repository.getSession();
      final userId = session['user_id'];
      final role = session['role'];
      
      if (userId != null && role != null) {
        final user = await _repository.getUserById(userId);
        if (user == null) {
          emit(Unauthenticated());
          return;
        }
        
        if (role == 'parent') {
          print('Verification abonnement pour parent: $userId');
          final sub = await _repository.checkSubscription(userId, user['school_id']);
          print('Subscription: $sub');
          
          final pendingPayment = await _repository.checkPendingPayment(userId);
          print('Paiement pending: $pendingPayment');
          
          if (pendingPayment != null) {
            print('PAIEMENT PENDING -> PaymentPendingPage');
            emit(PaymentSubmittedSuccessfully(
              parentId: userId,
              reference: pendingPayment['external_ref'],
              amount: pendingPayment['amount'],
              submittedAt: DateTime.parse(pendingPayment['created_at']),
              screenshotUrl: pendingPayment['screenshot_url'],
            ));
            return;
          }
          
          if (_isSubscriptionExpired(sub)) {
            print('ABONNEMENT EXPIRE -> SubscriptionExpired');
            emit(SubscriptionExpired(
              parentId: userId,
              schoolId: user['school_id'],
              expiresAt: _parseDate(sub?['trial_ends_at']) ?? _parseDate(sub?['current_period_end']),
              daysRemaining: sub?['days_remaining'],
              amount: sub?['amount'] ?? 1000,
              currency: sub?['currency'] ?? 'XOF',
              paymentPhoneNumber: sub?['payment_phone_number'],
            ));
            return;
          }
          print('Abonnement OK');
        }
        
        final schoolName = await _repository.getSchoolName(user['school_id']);
        
        Map<String, dynamic> parentData = {};
        if (role == 'parent') {
          parentData = await _repository.getParentDataLite(
            userId,
            await _repository.checkSubscription(userId, user['school_id']),
          );
        }
        
        _emitAuthenticated(user, schoolName, emit, parentData: parentData);
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      print('Erreur AppStarted: $e');
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginWithPhone(
    LoginWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    print('AUTHBLOC PHONE RECU: "${event.phone}"');
    
    try {
      final response = await _repository.loginByPhone(event.phone, event.password);

      if (response == null || response.isEmpty) {
        emit(AuthError('Erreur serveur'));
        return;
      }

      final result = response[0];
      
      if (result['success'] == true) {
        await _repository.saveSession(
          userId: result['user_id'],
          role: result['role'],
          firstName: result['first_name'],
          lastName: result['last_name'],
          schoolId: result['school_id'],
        );
        
        final schoolId = result['school_id'] as String?;
        String finalRole = result['role'];
        final phone = result['phone'] ?? event.phone;

        final roleFuture = (result['role'] == 'teacher' || result['role'] == 'admin' || result['role'] == 'assistant')
            ? _repository.getSpecificRole(result['user_id'], phone, schoolId)
            : Future.value(null);

        final schoolNameFuture = _repository.getSchoolName(schoolId);

        Map<String, dynamic>? sub;
        Map<String, dynamic>? pendingPayment;
        
        if (result['role'] == 'parent') {
          print('Verification abonnement pour parent: ${result['user_id']}');
          
          final results = await Future.wait([
            _repository.checkSubscription(result['user_id'], schoolId),
            _repository.checkPendingPayment(result['user_id']),
            schoolNameFuture,
          ]);
          
          sub = results[0] as Map<String, dynamic>?;
          pendingPayment = results[1] as Map<String, dynamic>?;
          
          print('Subscription: $sub');
          print('Paiement pending: $pendingPayment');
          
          if (pendingPayment != null) {
            print('PAIEMENT PENDING -> PaymentPendingPage');
            emit(PaymentSubmittedSuccessfully(
              parentId: result['user_id'],
              reference: pendingPayment['external_ref'],
              amount: pendingPayment['amount'],
              submittedAt: DateTime.parse(pendingPayment['created_at']),
              screenshotUrl: pendingPayment['screenshot_url'],
            ));
            return;
          }
          
          if (_isSubscriptionExpired(sub)) {
            print('ABONNEMENT EXPIRE -> SubscriptionExpired');
            emit(SubscriptionExpired(
              parentId: result['user_id'],
              schoolId: schoolId,
              expiresAt: _parseDate(sub?['trial_ends_at']) ?? _parseDate(sub?['current_period_end']),
              daysRemaining: sub?['days_remaining'],
              amount: sub?['amount'] ?? 1000,
              currency: sub?['currency'] ?? 'XOF',
              paymentPhoneNumber: sub?['payment_phone_number'],
            ));
            return;
          }
          print('Abonnement OK');
        }

        final specificRole = await roleFuture;
        final schoolName = result['role'] == 'parent' 
            ? (await schoolNameFuture)
            : await schoolNameFuture;
        
        if (specificRole != null) {
          print('Role specifique trouve: ${specificRole['code']}');
          finalRole = specificRole['code']!;
        }
        
        Map<String, dynamic> parentData = {};
        if (result['role'] == 'parent') {
          parentData = await _repository.getParentDataLite(result['user_id'], sub);
        }
        
        _emitAuthenticated({
          'id': result['user_id'],
          'first_name': result['first_name'],
          'last_name': result['last_name'],
          'role': finalRole,
          'school_id': schoolId,
          'email': result['email'],
          'phone': result['phone'],
        }, schoolName, emit, parentData: parentData);
      } else {
        emit(AuthError(result['message']));
      }
    } catch (e) {
      print('Erreur Login: $e');
      emit(AuthError('Erreur de connexion: $e'));
    }
  }

  Future<void> _onPaymentReferenceSubmitted(
    PaymentReferenceSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _repository.savePaymentTransaction(
        parentId: event.parentId,
        schoolId: event.schoolId,
        reference: event.reference,
        amount: event.amount,
        phoneNumber: event.phoneNumber,
        screenshotUrl: event.screenshotUrl,
      );

      print('Paiement enregistre: ${event.reference}');

      emit(PaymentSubmittedSuccessfully(
        parentId: event.parentId,
        reference: event.reference,
        amount: event.amount,
        submittedAt: DateTime.now(),
        screenshotUrl: event.screenshotUrl,
      ));
      
    } catch (e) {
      print('Erreur paiement: $e');
      emit(AuthError('Erreur lors de la soumission: $e'));
    }
  }

  Future<void> _onCheckSubscriptionStatus(
    CheckSubscriptionStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final session = await _repository.getSession();
      final userId = session['user_id'];
      final schoolId = session['school_id'];

      if (userId == null) {
        emit(Unauthenticated());
        return;
      }

      final sub = await _repository.checkSubscription(userId, schoolId);
      final pendingPayment = await _repository.checkPendingPayment(userId);

      if (pendingPayment != null) {
        emit(PaymentSubmittedSuccessfully(
          parentId: userId,
          reference: pendingPayment['external_ref'],
          amount: pendingPayment['amount'],
          submittedAt: DateTime.parse(pendingPayment['created_at']),
          screenshotUrl: pendingPayment['screenshot_url'],
        ));
        return;
      }

      if (_isSubscriptionExpired(sub)) {
        emit(SubscriptionExpired(
          parentId: userId,
          schoolId: schoolId,
          expiresAt: _parseDate(sub?['trial_ends_at']) ?? _parseDate(sub?['current_period_end']),
          daysRemaining: sub?['days_remaining'],
          amount: sub?['amount'] ?? 1000,
          currency: sub?['currency'] ?? 'XOF',
          paymentPhoneNumber: sub?['payment_phone_number'],
        ));
        return;
      }

      final user = await _repository.getUserById(userId);
      if (user == null) {
        emit(Unauthenticated());
        return;
      }

      final schoolName = await _repository.getSchoolName(schoolId);
      final parentData = await _repository.getParentDataLite(userId, sub);

      _emitAuthenticated(user, schoolName, emit, parentData: parentData);

    } catch (e) {
      print('Erreur check subscription: $e');
      emit(AuthError('Erreur: $e'));
    }
  }

  // ✅ CORRIGÉ : Protection contre blocage + emit garanti
  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await _repository.clearSession();
    } catch (e) {
      print('Erreur clearSession: $e');
    }
    emit(Unauthenticated());
  }
}