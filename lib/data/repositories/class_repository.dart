// lib/data/repositories/class_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../data/models/class_model.dart';
import '../models/teacher_class_schedule_model.dart';

class ClassRepository {
  final SupabaseClient _supabase;

  ClassRepository(this._supabase);

  Future<List<ClassModel>> getAllClasses() async {
    final response = await _supabase
        .from('classes')
        .select('*')
        .order('name');

    return (response as List)
        .map((json) => ClassModel.fromJson(json))
        .toList();
  }

  Future<List<ClassModel>> getTeacherClasses({String? teacherId}) async {
    final id = teacherId ?? _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('Non authentifie');

    final response = await _supabase
        .from('schedules')
        .select('class_id')
        .eq('teacher_id', id);

    final classIds = (response as List)
        .map((json) => json['class_id'] as String)
        .toSet()
        .toList();

    if (classIds.isEmpty) return [];

    final classesResponse = await _supabase
        .from('classes')
        .select('*')
        .inFilter('id', classIds);

    return (classesResponse as List)
        .map((json) => ClassModel.fromJson(json))
        .toList();
  }

  Future<ClassModel?> getClassById(String classId) async {
    final response = await _supabase
        .from('classes')
        .select('*')
        .eq('id', classId)
        .maybeSingle();

    if (response == null) return null;
    return ClassModel.fromJson(response);
  }

   Future<List<ClassModel>> getClassesBySchoolId(String schoolId) async {
    final response = await _supabase
        .from('classes')
        .select('*')
        .eq('school_id', schoolId)
        .order('name');

    return (response as List).map((json) => ClassModel.fromJson(json)).toList();
  }

  Future<List<TeacherClassScheduleModel>> getTeacherSchedule({String? teacherId}) async {
    final id = teacherId ?? _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('Non authentifié');

    final response = await _supabase
        .from('schedules')
        .select('*')
        .eq('teacher_id', id)
        .eq('is_active', true);

    return (response as List)
        .map((json) => TeacherClassScheduleModel.fromJson(json))
        .toList();
  }
}