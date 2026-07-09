// lib/presentation/blocs/school_report/school_report_counter.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'school_report_utils.dart';

class SchoolReportCounter {
  final _supabase = Supabase.instance.client;

  Future<int> countAttendance({
    required String schoolId,
    required String? periodId,
    required String? startDate,
    required String? endDate,
    required String? classId,
    required String? studentId,
    required String? subjectId,
    required String? teacherId,
  }) async {
    try {
      final response = await _supabase.rpc('count_attendance', params: {
        'p_school_id': schoolId,
        'p_period_id': periodId,
        'p_start_date': startDate,
        'p_end_date': endDate,
        'p_class_id': classId,
        'p_student_id': studentId,
        'p_subject_id': subjectId,
        'p_teacher_id': teacherId,
      });
      return parseCount(response);
    } catch (e) {
      print('Erreur count attendance: $e');
      return 0;
    }
  }

  Future<int> countGrades({
    required String schoolId,
    required String? periodId,
    required String? startDate,
    required String? endDate,
    required String? classId,
    required String? studentId,
    required String? subjectId,
    required String? teacherId,
  }) async {
    try {
      final response = await _supabase.rpc('count_grades', params: {
        'p_school_id': schoolId,
        'p_period_id': periodId,
        'p_start_date': startDate,
        'p_end_date': endDate,
        'p_class_id': classId,
        'p_student_id': studentId,
        'p_subject_id': subjectId,
        'p_teacher_id': teacherId,
      });
      return parseCount(response);
    } catch (e) {
      print('Erreur count grades: $e');
      return 0;
    }
  }
}
