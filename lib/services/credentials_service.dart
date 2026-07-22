// lib/services/credentials_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modèle représentant un credential affichable
class UserCredential {
  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final String phone;
  final String? email;
  final String? schoolId;
  final String? schoolName;
  final String? matricule; // Pour parent (matricule de l'enfant)
  final String generatedPassword;

  UserCredential({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.phone,
    this.email,
    this.schoolId,
    this.schoolName,
    this.matricule,
    required this.generatedPassword,
  });

  String get fullName => '$firstName $lastName';
  String get displayRole {
    switch (role) {
      case 'parent':
        return 'Parent';
      case 'teacher':
        return 'Enseignant';
      default:
        return role;
    }
  }
}

class CredentialsService {
  final SupabaseClient _supabase;

  CredentialsService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// ============================================================
  /// RÉCUPÉRER TOUS LES CREDENTIALS (SUPER ADMIN)
  /// ============================================================
  Future<List<UserCredential>> getAllCredentials() async {
    // 1. Récupérer parents et enseignants uniquement
    final usersResponse = await _supabase
        .from('app_users')
        .select('''
          id,
          first_name,
          last_name,
          role,
          phone,
          email,
          school_id,
          schools:school_id(name)
        ''')
        .inFilter('role', ['parent', 'teacher'])
        .order('role')
        .order('last_name');

    final users = (usersResponse as List).cast<Map<String, dynamic>>();

    // 2. Récupérer les matricules pour parents
    final parentStudentMap = await _getParentStudentMap();

    // 3. Construire les credentials
    return users.map((u) {
      final role = u['role'] as String;
      final firstName = u['first_name'] as String? ?? '';
      final lastName = u['last_name'] as String? ?? '';
      final schoolData = u['schools'] as Map<String, dynamic>?;

      String generatedPassword;
      String? matricule;

      if (role == 'teacher') {
        // Format: InitialePrénom + NomMAJ
        final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
        generatedPassword = '$initial${lastName.toUpperCase()}';
      } else if (role == 'parent') {
        // Matricule de l'enfant via parent_students
        matricule = parentStudentMap[u['id'] as String];
        generatedPassword = matricule ?? 'N/A';
      } else {
        generatedPassword = 'N/A';
      }

      return UserCredential(
        id: u['id'] as String,
        firstName: firstName,
        lastName: lastName,
        role: role,
        phone: u['phone'] as String? ?? '',
        email: u['email'] as String?,
        schoolId: u['school_id'] as String?,
        schoolName: schoolData?['name'] as String?,
        matricule: matricule,
        generatedPassword: generatedPassword,
      );
    }).toList();
  }

  /// ============================================================
  /// RÉCUPÉRER LES CREDENTIALS D'UNE ÉCOLE (ADMIN ÉCOLE)
  /// ============================================================
  Future<List<UserCredential>> getSchoolCredentials(String schoolId) async {
    // 1. Récupérer les users de cette école uniquement
    final usersResponse = await _supabase
        .from('app_users')
        .select('''
          id,
          first_name,
          last_name,
          role,
          phone,
          email,
          school_id
        ''')
        .eq('school_id', schoolId)
        .inFilter('role', ['parent', 'teacher'])
        .order('role')
        .order('last_name');

    final users = (usersResponse as List).cast<Map<String, dynamic>>();

    // 2. Récupérer les matricules pour parents de cette école
    final parentStudentMap = await _getParentStudentMap(schoolId: schoolId);

    // 3. Construire les credentials
    return users.map((u) {
      final role = u['role'] as String;
      final firstName = u['first_name'] as String? ?? '';
      final lastName = u['last_name'] as String? ?? '';

      String generatedPassword;
      String? matricule;

      if (role == 'teacher') {
        final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
        generatedPassword = '$initial${lastName.toUpperCase()}';
      } else if (role == 'parent') {
        matricule = parentStudentMap[u['id'] as String];
        generatedPassword = matricule ?? 'N/A';
      } else {
        generatedPassword = 'N/A';
      }

      return UserCredential(
        id: u['id'] as String,
        firstName: firstName,
        lastName: lastName,
        role: role,
        phone: u['phone'] as String? ?? '',
        email: u['email'] as String?,
        schoolId: schoolId,
        schoolName: null,
        matricule: matricule,
        generatedPassword: generatedPassword,
      );
    }).toList();
  }

  /// ============================================================
  /// HELPER — Map: parent_id (app_users.id) → matricule de l'enfant
  /// ============================================================
  Future<Map<String, String>> _getParentStudentMap({String? schoolId}) async {
    var query = _supabase.from('parent_students').select('''
          parent_id,
          students!inner(matricule, school_id)
        ''');

    if (schoolId != null) {
      query = query.eq('students.school_id', schoolId);
    }

    final response = await query;
    final records = (response as List).cast<Map<String, dynamic>>();

    final Map<String, String> map = {};
    for (final record in records) {
      final parentId = record['parent_id'] as String?;
      final student = record['students'] as Map<String, dynamic>?;
      final matricule = student?['matricule'] as String?;

      if (parentId != null && matricule != null) {
        map[parentId] = matricule;
      }
    }
    return map;
  }
}
