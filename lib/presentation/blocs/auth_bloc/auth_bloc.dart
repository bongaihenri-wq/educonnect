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
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final role = prefs.getString('role');
      
      if (userId != null && role != null) {
        // Récupérer les infos depuis Supabase
        final user = await _supabase
            .from('app_users')
            .select('id, first_name, last_name, role, school_id')
            .eq('id', userId)
            .single();
        
        // ✅ CORRIGÉ : Récupérer schoolName AVANT emit
        final schoolName = await _getSchoolName(user['school_id']);
        
        _emitAuthenticated(user, schoolName, emit);
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginWithPhone(
    LoginWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
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
        // Sauvegarder la session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', result['user_id']);
        await prefs.setString('role', result['role']);
        await prefs.setString('first_name', result['first_name']);
        await prefs.setString('last_name', result['last_name']);
        await prefs.setString('school_id', result['school_id']);
        
        // ✅ CORRIGÉ : Récupérer schoolName AVANT emit
        final schoolName = await _getSchoolName(result['school_id']);
        
        // ✅ CORRIGÉ : Récupérer données parent si nécessaire
        Map<String, dynamic> parentData = {};
        if (result['role'] == 'parent') {
          parentData = await _getParentData(result['user_id']);
        }
        
        _emitAuthenticated({
          'id': result['user_id'],
          'first_name': result['first_name'],
          'last_name': result['last_name'],
          'role': result['role'],
          'school_id': result['school_id'],
        }, schoolName, emit, parentData: parentData);
      } else {
        emit(AuthError(result['message']));
      }
    } catch (e) {
      emit(AuthError('Erreur de connexion: $e'));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    emit(Unauthenticated());
  }

  // ✅ CORRIGÉ : Helper pour récupérer le nom de l'école
  Future<String> _getSchoolName(String schoolId) async {
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

  // ✅ CORRIGÉ : Helper pour récupérer les données parent
  Future<Map<String, dynamic>> _getParentData(String parentId) async {
    try {
      final parentStudent = await _supabase
          .from('parent_students')
          .select('student_id')
          .eq('parent_id', parentId)
          .single();
      
      if (parentStudent != null) {
        final student = await _supabase
            .from('students')
            .select('*, classes(name)')
            .eq('id', parentStudent['student_id'])
            .single();
        
        if (student != null) {
          return {
            'studentId': student['id'],
            'studentName': '${student['first_name']} ${student['last_name']}',
            'studentMatricule': student['matricule'] ?? '',
            'className': student['classes']?['name'] ?? 'Classe inconnue',
          };
        }
      }
    } catch (e) {
      print('❌ Erreur récupération parent data: $e');
    }
    return {};
  }

  // ✅ CORRIGÉ : Synchrone - plus d'async ici !
  void _emitAuthenticated(
    Map<String, dynamic> user,
    String schoolName,
    Emitter<AuthState> emit, {
    Map<String, dynamic> parentData = const {},
  }) {
    final role = user['role'];
    
    if (role == 'admin') {
      emit(AdminAuthenticated(
        userId: user['id'],
        firstName: user['first_name'],
        lastName: user['last_name'],
        schoolId: user['school_id'],
        schoolName: schoolName,
      ));
    } else if (role == 'teacher') {
      emit(TeacherAuthenticated(
        userId: user['id'],
        firstName: user['first_name'],
        lastName: user['last_name'],
        schoolId: user['school_id'],
        schoolName: schoolName,
      ));
    } else if (role == 'parent') {
      emit(ParentAuthenticated(
        userId: user['id'],
        firstName: user['first_name'],
        lastName: user['last_name'],
        schoolId: user['school_id'],
        schoolName: schoolName,
        studentId: parentData['studentId'] ?? '',
        studentName: parentData['studentName'] ?? '',
        studentMatricule: parentData['studentMatricule'] ?? '',
        className: parentData['className'] ?? '',
      ));
    } else {
      emit(AuthError('Rôle inconnu: $role'));
    }
  }
}
