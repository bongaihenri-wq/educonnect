
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../data/models/class_model.dart';
import '../models/teacher_class_schedule_model.dart';

class ClassRepository {
  final SupabaseClient _supabase;

  ClassRepository(this._supabase);

  /// Recuperer toutes les classes de l etablissement
  Future<List<ClassModel>> getAllClasses() async {
    final response = await _supabase
        .from('classes')
        .select('''
          *,
          levels(name),
          teachers(first_name, last_name)
        ''')
        .order('name');

    return (response as List)
        .map((json) => ClassModel.fromJson(json))
        .toList();
  }

  /// Recuperer les classes assignees a un enseignant
  Future<List<ClassModel>> getTeacherClasses() async {
    final teacherId = _supabase.auth.currentUser?.id;
    if (teacherId == null) throw Exception('Non authentifie');

    final response = await _supabase
        .from('teacher_assignments')
        .select('''
          classes(
            id,
            name,
            capacity,
            levels(name),
            teachers(first_name, last_name)
          )
        ''')
        .eq('teacher_id', teacherId);

    return (response as List)
        .map((json) => ClassModel.fromJson(json['classes']))
        .toList();
  }

  /// Recuperer une classe par son ID
  Future<ClassModel?> getClassById(String classId) async {
    final response = await _supabase
        .from('classes')
        .select('''
          *,
          levels(name),
          teachers(first_name, last_name)
        ''')
        .eq('id', classId)
        .maybeSingle();

    if (response == null) return null;
    return ClassModel.fromJson(response);
  }

  /// Recuperer les classes d un niveau specifique
  Future<List<ClassModel>> getClassesByLevel(String levelId) async {
    final response = await _supabase
        .from('classes')
        .select('''
          *,
          levels(name),
          teachers(first_name, last_name)
        ''')
        .eq('level_id', levelId)
        .order('name');

    return (response as List)
        .map((json) => ClassModel.fromJson(json))
        .toList();
  }
// ⭐ NOUVELLE MÉTHODE À AJOUTER
  Future<List<TeacherClassScheduleModel>> getTeacherSchedule() async {
    final teacherId = _supabase.auth.currentUser?.id;
    if (teacherId == null) throw Exception('Non authentifié');

    final response = await _supabase.rpc(
      'get_teacher_classes_with_schedule',
      params: {'p_teacher_id': teacherId},
    );
    
    return (response as List)
        .map((json) => TeacherClassScheduleModel.fromJson(json))
        .toList();
  }

}
