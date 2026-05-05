import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_model.dart';

class CourseRepository {
  final SupabaseClient _supabase;

  CourseRepository(this._supabase);

  /// Recuperer les cours d une classe pour un jour specifique
  Future<List<CourseModel>> getCoursesByClass(String classId) async {
    final response = await _supabase
        .from('schedules')
        .select('''
          id,
          day_of_week,
          start_time,
          end_time,
          room,
          school_id,
          subjects(id, name),
          classes(id, name),
          teacher:teacher_id(id, first_name, last_name)
        ''')
        .eq('class_id', classId)
        .order('start_time');

    return (response as List).map((json) => _mapToCourseModel(json)).toList();
  }

  /// Recuperer les cours d un enseignant
  Future<List<CourseModel>> getTeacherCourses(String teacherId) async {
    final response = await _supabase
        .from('schedules')
        .select('''
          id,
          day_of_week,
          start_time,
          end_time,
          room,
          subjects(id, name),
          classes(id, name),
          teacher:teacher_id(id, first_name, last_name)
        ''')
        .eq('teacher_id', teacherId)
        .order('day_of_week')
        .order('start_time');

    return (response as List).map((json) => _mapToCourseModel(json)).toList();
  }

  /// Mapper le JSON Supabase vers CourseModel
  CourseModel _mapToCourseModel(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'],
      name: json['subjects']?['name'] ?? 'Cours',
      subjectId: json['subjects']?['id'] ?? '',
      classId: json['classes']?['id'] ?? '',
      teacherId: json['teacher']?['id'] ?? '',
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      room: json['room'],
      subjectName: json['subjects']?['name'],
      teacherName: json['teacher'] != null
          ? '${json['teacher']['first_name']} ${json['teacher']['last_name']}'
          : null, schoolId: '',
    );
  }
}