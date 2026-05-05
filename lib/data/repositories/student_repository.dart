import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';

class StudentRepository {
  final SupabaseClient _supabase;

  StudentRepository(this._supabase);

  /// Recuperer tous les eleves de l etablissement
  Future<List<StudentModel>> getAllStudents() async {
    final response = await _supabase
        .from('students')
        .select('*, classes(name, levels(name)), parent_profiles(users(first_name, last_name))')
        .order('last_name');

    return (response as List)
        .map((json) => StudentModel.fromJson(json))
        .toList();
  }

  /// Recuperer les eleves d une classe specifique (pour l appel)
 Future<List<StudentModel>> getStudentsByClass(String classId) async {
  if (classId.isEmpty) {
    print('❌ classId est vide !');
    return [];
  }
  
  try {
    final response = await _supabase
        .from('students')
        .select('*')  // ✅ Simplifié - juste les colonnes de students
        .eq('class_id', classId)
        .order('last_name')
        .order('first_name');

    print('✅ ${response.length} élèves trouvés pour classId: $classId');
    
    return (response as List)
        .map((json) => StudentModel.fromJson(json))
        .toList();
  } catch (e) {
    print('❌ ERREUR getStudentsByClass: $e');
    return [];  // ✅ Retourne vide au lieu de planter
  }
}

  /// Recuperer un eleve par son ID
  Future<StudentModel?> getStudentById(String studentId) async {
    final response = await _supabase
        .from('students')
        .select('*, classes(name, levels(name)), parent_profiles(users(first_name, last_name))')
        .eq('id', studentId)
        .maybeSingle();

    if (response == null) return null;
    return StudentModel.fromJson(response);
  }

  /// Recuperer les eleves d un parent (pour le dashboard parent)
  Future<List<StudentModel>> getStudentsByParent(String parentId) async {
    final response = await _supabase
        .from('parent_students')
        .select('students(*, classes(name, levels(name)))')
        .eq('parent_id', parentId);

    return (response as List)
        .map((json) => StudentModel.fromJson(json['students']))
        .toList();
  }

  /// Rechercher un eleve par nom ou matricule
  Future<List<StudentModel>> searchStudents(String query) async {
    final response = await _supabase
        .from('students')
        .select('*, classes(name, levels(name))')
        .or('first_name.ilike.%$query%,last_name.ilike.%$query%,matricule.ilike.%$query%')
        .order('last_name');

    return (response as List)
        .map((json) => StudentModel.fromJson(json))
        .toList();
  }

  /// Creer un nouvel eleve
  Future<StudentModel> createStudent({
    required String firstName,
    required String lastName,
    required String matricule,
    required String classId,
    DateTime? birthDate,
    String? gender,
  }) async {
    final response = await _supabase
        .from('students')
        .insert({
          'first_name': firstName,
          'last_name': lastName,
          'matricule': matricule,
          'class_id': classId,
          'birth_date': birthDate?.toIso8601String().split('T')[0],
          'gender': gender,
        })
        .select()
        .single();

    return StudentModel.fromJson(response);
  }

  /// Mettre a jour un eleve
  Future<StudentModel> updateStudent(
    String studentId, {
    String? firstName,
    String? lastName,
    String? classId,
    DateTime? birthDate,
    String? gender,
  }) async {
    final Map<String, dynamic> updates = {};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (classId != null) updates['class_id'] = classId;
    if (birthDate != null) updates['birth_date'] = birthDate.toIso8601String().split('T')[0];
    if (gender != null) updates['gender'] = gender;

    final response = await _supabase
        .from('students')
        .update(updates)
        .eq('id', studentId)
        .select()
        .single();

    return StudentModel.fromJson(response);
  }
}
