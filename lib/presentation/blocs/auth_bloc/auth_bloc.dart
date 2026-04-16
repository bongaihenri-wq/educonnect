// lib/presentation/blocs/auth_bloc/auth_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/school_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient _client = Supabase.instance.client;

  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<TeacherLoginRequested>(_onTeacherLoginRequested);
    on<ParentLoginRequested>(_onParentLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      if (!SchoolService.isConfigured) {
        print('⚠️ AuthBloc - Aucune école configurée');
        emit(Unauthenticated());
        return;
      }

      final schoolId = SchoolService.currentSchoolId;
      if (schoolId == null) {
        print('⚠️ AuthBloc - school_id null');
        emit(Unauthenticated());
        return;
      }

      final session = _client.auth.currentSession;
      
      if (session != null) {
        final userData = await _client
            .from('users')
            .select('*, schools(id, name)')
            .eq('auth_id', session.user.id)
            .eq('school_id', schoolId)  // ✅ Corrigé
            .maybeSingle();

        if (userData != null) {
          final role = userData['role'];
          final schoolName = userData['schools']['name'];
          final schoolIdFromDb = userData['schools']['id'];

          if (role == 'teacher' || role == 'admin' || role == 'staff') {
            emit(TeacherAuthenticated(
              userData: userData,
              schoolName: schoolName,
              schoolId: schoolIdFromDb,
            ));
            return;
          }
        }
      }

      // TODO: Vérifier session parent
      emit(Unauthenticated());
      
    } catch (e) {
      print('💥 AuthBloc - Erreur AppStarted: $e');
      emit(Unauthenticated());
    }
  }
  

Future<void> _onTeacherLoginRequested(
  TeacherLoginRequested event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());
  
  try {
    print('🔍 Connexion enseignant: ${event.email}');

    // 1. Configurer l'école
    final isValid = await SchoolService.setApiKey(event.apiKey);
    if (!isValid) {
      emit(AuthError('Code école invalide'));
      emit(Unauthenticated());
      return;
    }

    final schoolId = SchoolService.currentSchoolId;
    print('🏫 School ID: $schoolId');

    // 2. Vérifier email + password + école en UNE requête
    final userData = await _client
        .from('users')
        .select('*, schools(id, name), teacher_profiles(*)')
        .eq('email', event.email)
        .eq('password_hash', event.password)  // Vérification ici
        .eq('school_id', schoolId!)
        .eq('role', 'teacher')
        .maybeSingle();

    print('👤 Résultat: ${userData != null ? 'TROUVE' : 'NON TROUVE'}');

    if (userData == null) {
      emit(AuthError('Email ou mot de passe incorrect'));
      emit(Unauthenticated());
      return;
    }

    final schoolName = userData['schools']['name'];
    print('✅ Connecté: ${userData['first_name']} ${userData['last_name']}');

    emit(TeacherAuthenticated(
      userData: userData,
      schoolName: schoolName,
      schoolId: userData['schools']['id'],
    ));

  } catch (e, stackTrace) {
    print('💥 ERREUR: $e');
    print('📍 Stack: $stackTrace');
    await SchoolService.clear();
    emit(AuthError('Erreur de connexion'));
    emit(Unauthenticated());
  }
}

Future<void> _onParentLoginRequested(
  ParentLoginRequested event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());
  
  // LOGS CRITIQUES - toujours visibles
  debugPrint('🔥 CONNEXION PARENT DEMARREE');
  debugPrint('📱 Phone brut: [${event.phone}]');
  debugPrint('🎓 Matricule: [${event.matricule}]');
  debugPrint('🔑 API Key: [${event.apiKey}]');
  
  try {
    // Nettoyer téléphone
    final cleanPhone = event.phone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    debugPrint('📱 Phone nettoye: [$cleanPhone]');

    // 1. Vérifier API Key
    debugPrint('🔧 Verification API Key...');
    final isValid = await SchoolService.setApiKey(event.apiKey);
    debugPrint('✅ API Key valide: $isValid');
    
    if (!isValid) {
      debugPrint('❌ API KEY INVALIDE');
      emit(AuthError('Code ecole invalide'));
      emit(Unauthenticated());
      return;
    }

    final schoolId = SchoolService.currentSchoolId;
    debugPrint('🏫 School ID: [$schoolId]');

    if (schoolId == null) {
      debugPrint('❌ SCHOOL ID NULL');
      emit(AuthError('Erreur ecole'));
      emit(Unauthenticated());
      return;
    }

    // 2. Chercher élève
    debugPrint('🔍 Recherche eleve...');
    final student = await _client
        .from('students')
        .select('id, first_name, last_name, matricule, school_id, classes(name), schools(id, name)')
        .eq('matricule', event.matricule.toUpperCase().trim())
        .eq('school_id', schoolId)
        .maybeSingle();

    debugPrint('👤 Eleve result: ${student != null ? 'TROUVE' : 'NON TROUVE'}');
    debugPrint('👤 Eleve data: $student');

    if (student == null) {
      debugPrint('❌ ELEVE NON TROUVE');
      await SchoolService.clear();
      emit(AuthError('Matricule non trouve'));
      emit(Unauthenticated());
      return;
    }

    // 3. Chercher parent
    debugPrint('🔍 Recherche parent avec phone: [$cleanPhone]');
    debugPrint('🔍 Student ID: [${student['id']}]');
    
    final parentLink = await _client
        .from('parent_students')
        .select('''
          relationship,
          parent:users!inner(id, first_name, last_name, phone, role)
        ''')
        .eq('student_id', student['id'])
        .eq('parent.phone', cleanPhone)
        .eq('parent.role', 'parent')
        .maybeSingle();

    debugPrint('👨‍👩‍👧 Parent result: ${parentLink != null ? 'TROUVE' : 'NON TROUVE'}');
    debugPrint('👨‍👩‍👧 Parent data: $parentLink');

    if (parentLink == null) {
      debugPrint('❌ PARENT NON TROUVE');
      await SchoolService.clear();
      emit(AuthError('Numero non reconnu'));
      emit(Unauthenticated());
      return;
    }

    final parent = parentLink['parent'];
    final schoolName = student['schools']?['name'] ?? 'Ecole inconnue';

    debugPrint('✅ CONNEXION REUSSIE !');
    debugPrint('👤 Parent: ${parent['first_name']} ${parent['last_name']}');

    // Sauvegarder
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parent_id', parent['id']);
    await prefs.setString('student_id', student['id']);

    emit(ParentAuthenticated(
      parentData: parent,
      studentData: student,
      relationship: parentLink['relationship'] ?? 'parent',
      schoolName: schoolName,
      schoolId: student['schools']?['id'] ?? schoolId,
    ));

  } catch (e, stackTrace) {
    debugPrint('💥 ERREUR CRITIQUE: $e');
    debugPrint('📍 STACK: $stackTrace');
    await SchoolService.clear();
    emit(AuthError('Erreur technique'));
    emit(Unauthenticated());
  }
}

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      await _client.auth.signOut();
      await SchoolService.clear();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('parent_id');
      await prefs.remove('student_id');
      
      emit(Unauthenticated());
    } catch (e) {
      emit(Unauthenticated());
    }
  }
}
