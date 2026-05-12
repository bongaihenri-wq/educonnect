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
        final user = await _supabase
            .from('app_users')
            .select('id, first_name, last_name, role, school_id, email, phone')
            .eq('id', userId)
            .single();
        
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

    // ⭐ DEBUG
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
        
        // ⭐ CORRIGÉ : school_id peut être null pour super_admin
        final schoolId = result['school_id'] as String?;
        if (schoolId != null) {
          await prefs.setString('school_id', schoolId);
        } else {
          await prefs.remove('school_id');
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
          'school_id': schoolId, // peut être null
          'email': result['email'],
          'phone': result['phone'],
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
      ));
    } else {
      emit(AuthError('Rôle inconnu: $role'));
    }
  }
}