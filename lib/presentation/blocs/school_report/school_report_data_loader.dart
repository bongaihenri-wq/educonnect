// lib/presentation/blocs/school_report/school_report_data_loader.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SchoolReportDataLoader {
  final _supabase = Supabase.instance.client;
  static const int _pageSize = 50;

  Future<List<Map<String, dynamic>>> loadAttendance({
    required String schoolId,
    required String? periodId,
    required String? startDate,
    required String? endDate,
    required String? classId,
    required String? studentId,
    required String? subjectId,
    required String? teacherId,
    required int page,
  }) async {
    var query = _supabase.from('attendance').select('''
      id,
      date,
      status,
      student_id,
      students(id, first_name, last_name, matricule),
      schedules(start_time, end_time, subjects(name), classes(level, name), teacher_id),
      teachers:app_users!attendance_teacher_id_fkey(first_name, last_name)
    ''');

    query = query.eq('school_id', schoolId);

    if (periodId != null) {
      final period = await _supabase
          .from('school_trimester_definitions')
          .select('start_date, end_date')
          .eq('id', periodId)
          .single();

      final periodStart = period['start_date'] as String?;
      final periodEnd = period['end_date'] as String?;

      if (periodStart != null) {
        query = query.gte('date', periodStart.split('T')[0]);
      }
      if (periodEnd != null) {
        query = query.lte('date', periodEnd.split('T')[0]);
      }
    } else if (startDate != null && endDate != null) {
      query = query.gte('date', startDate);
      query = query.lte('date', endDate);
    }

    if (classId != null) query = query.eq('schedules.class_id', classId);
    if (studentId != null) query = query.eq('student_id', studentId);
    if (subjectId != null) query = query.eq('schedules.subject_id', subjectId);
    if (teacherId != null) query = query.eq('schedules.teacher_id', teacherId);

    final response = await query
        .order('date', ascending: false)
        .range(page * _pageSize, (page + 1) * _pageSize - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> loadGrades({
    required String schoolId,
    required String? periodId,
    required String? startDate,
    required String? endDate,
    required String? classId,
    required String? studentId,
    required String? subjectId,
    required String? teacherId,
    required int page,
  }) async {
    var query = _supabase.from('grades').select('''
      id,
      score,
      max_score,
      coefficient,
      date,
      student_id,
      students(id, first_name, last_name, matricule),
      subjects(name),
      classes(level, name),
      teacher_id
    ''');

    query = query.eq('school_id', schoolId);

    if (periodId != null) {
      final period = await _supabase
          .from('school_trimester_definitions')
          .select('start_date, end_date')
          .eq('id', periodId)
          .single();

      final periodStart = period['start_date'] as String?;
      final periodEnd = period['end_date'] as String?;

      if (periodStart != null) {
        query = query.gte('date', periodStart.split('T')[0]);
      }
      if (periodEnd != null) {
        query = query.lte('date', periodEnd.split('T')[0]);
      }
    } else if (startDate != null && endDate != null) {
      query = query.gte('date', startDate);
      query = query.lte('date', endDate);
    }

    if (classId != null) query = query.eq('class_id', classId);
    if (studentId != null) query = query.eq('student_id', studentId);
    if (subjectId != null) query = query.eq('subject_id', subjectId);
    if (teacherId != null) query = query.eq('teacher_id', teacherId);

    final response = await query
        .order('date', ascending: false)
        .range(page * _pageSize, (page + 1) * _pageSize - 1);

    return List<Map<String, dynamic>>.from(response);
  }
}
