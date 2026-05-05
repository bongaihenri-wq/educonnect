// lib/data/repositories/attendance_repository.dart
import 'package:educonnect/data/models/attendance_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/attendance.dart';

class AttendanceRepository {
  final SupabaseClient _supabase;

  AttendanceRepository(this._supabase);

  // ============================================================
  // SAUVEGARDE DES PRÉSENCES
  // ============================================================
  Future<void> saveAttendance({
    required String classId,
    required String courseId,
    required DateTime date,
    required Map<String, AttendanceStatus> records,
    required String schoolId,
    required String teacherId,
  }) async {
    if (schoolId.isEmpty) throw Exception('schoolId requis');
    if (teacherId.isEmpty) throw Exception('teacherId requis');
    if (classId.isEmpty) throw Exception('classId requis');

    final dateStr = date.toIso8601String().split('T')[0];
    final now = DateTime.now().toIso8601String();

    final attendances = records.entries.map((entry) => {
      'student_id': entry.key,
      'class_id': classId,
      'schedule_id': courseId.isNotEmpty ? courseId : null,
      'teacher_id': teacherId,
      'school_id': schoolId,
      'date': dateStr,
      'status': entry.value.value,
      'created_at': now,
      'updated_at': now,
    }).toList();

    try {
      await _supabase
          .from('attendance')
          .delete()
          .eq('class_id', classId)
          .eq('date', dateStr)
          .eq('teacher_id', teacherId)
          .eq('school_id', schoolId);

      if (attendances.isNotEmpty) {
        await _supabase.from('attendance').insert(attendances);
      }
    } catch (e) {
      throw Exception('Erreur sauvegarde présences: $e');
    }
  }

  // ============================================================
  // RÉCUPÉRATION PAR ÉLÈVE
  // ============================================================
  Future<List<Attendance>> getStudentAttendance(
    String studentId, {
    String? schoolId,
  }) async {
    var query = _supabase
        .from('attendance')
        .select()
        .eq('student_id', studentId);

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }

    final response = await query.order('date', ascending: false);
    return (response as List)
        .map((json) => Attendance.fromJson(json))
        .toList();
  }

  // ============================================================
  // RÉCUPÉRATION PAR CLASSE ET DATE
  // ============================================================
  Future<Map<String, AttendanceStatus>> getClassAttendance({
    required String classId,
    required DateTime date,
    String? schoolId,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];

    var query = _supabase
        .from('attendance')
        .select()
        .eq('class_id', classId)
        .eq('date', dateStr);

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }

    final response = await query;

    final result = <String, AttendanceStatus>{};
    for (final record in response as List) {
      result[record['student_id']] = _parseStatus(record['status']);
    }
    return result;
  }

  // ============================================================
  // VÉRIFICATION EXISTANCE
  // ============================================================
  Future<bool> checkExistingAttendance({
    required String classId,
    required String courseId,
    required DateTime date,
    required String teacherId,
    String? schoolId,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];

    var query = _supabase
        .from('attendance')
        .select('id')
        .eq('class_id', classId)
        .eq('schedule_id', courseId)
        .eq('date', dateStr)
        .eq('teacher_id', teacherId);

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }

    final response = await query.limit(1);
    return (response as List).isNotEmpty;
  }

  // ============================================================
  // NOTIFICATIONS PARENTS
  // ============================================================
  Future<void> notifyParents({
    required List<String> studentIds,
    required DateTime date,
    String? className,
    String? courseName,
    required String schoolId,
  }) async {
    if (studentIds.isEmpty) return;
    if (schoolId.isEmpty) throw Exception('schoolId requis');

    try {
      final parentsResponse = await _supabase
          .from('parent_students')
          .select('''
            parent_id,
            students!inner(id, first_name, last_name, school_id)
          ''')
          .inFilter('student_id', studentIds)
          .eq('students.school_id', schoolId);

      final notifications = <Map<String, dynamic>>[];

      for (final link in parentsResponse as List) {
        final parentId = link['parent_id'];
        final student = link['students'];

        if (student['school_id'] != schoolId) continue;

        notifications.add({
          'user_id': parentId,
          'title': 'Absence / Retard',
          'message': _buildNotificationMessage(
            student['first_name'],
            student['last_name'],
            className,
            courseName,
            date,
          ),
          'type': 'attendance',
          'read': false,
          'created_at': DateTime.now().toIso8601String(),
          'student_id': student['id'],
          'school_id': schoolId,
        });
      }

      if (notifications.isNotEmpty) {
        await _supabase.from('notifications').insert(notifications);
      }
    } catch (e) {
      debugPrint('Erreur notification parents: $e');
    }
  }

  // ============================================================
  // STATISTIQUES CLASSE
  // ============================================================
  Future<Map<String, dynamic>> getClassStats({
    required String classId,
    required DateTime startDate,
    required DateTime endDate,
    String? schoolId,
  }) async {
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    var query = _supabase
        .from('attendance')
        .select('status')
        .eq('class_id', classId)
        .gte('date', startStr)
        .lte('date', endStr);

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }

    final response = await query;
    final records = response as List;

    final presentCount = records.where((r) => r['status'] == 'present').length;
    final absentCount = records.where((r) => r['status'] == 'absent').length;
    final lateCount = records.where((r) => r['status'] == 'late').length;
    final total = records.length;

    return {
      'total_records': total,
      'present_count': presentCount,
      'absent_count': absentCount,
      'late_count': lateCount,
      'present_rate': total > 0 ? (presentCount / total * 100).toStringAsFixed(1) : '0',
      'absent_rate': total > 0 ? (absentCount / total * 100).toStringAsFixed(1) : '0',
      'late_rate': total > 0 ? (lateCount / total * 100).toStringAsFixed(1) : '0',
    };
  }

  // ============================================================
  // STATISTIQUES ÉLÈVE
  // ============================================================
  Future<Map<String, dynamic>> getStudentStats({
    required String studentId,
    String? schoolId,
  }) async {
    var query = _supabase
        .from('attendance')
        .select('status')
        .eq('student_id', studentId);

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }

    final response = await query;
    final records = response as List;

    final total = records.length;
    final present = records.where((r) => r['status'] == 'present').length;
    final absent = records.where((r) => r['status'] == 'absent').length;
    final late = records.where((r) => r['status'] == 'late').length;

    return {
      'total': total,
      'present': present,
      'absent': absent,
      'late': late,
      'rate': total > 0 ? (present / total * 100).toStringAsFixed(1) : '0',
    };
  }

  // ============================================================
  // ABSENCES FRÉQUENTES (RPC)
  // ============================================================
  Future<List<Map<String, dynamic>>> getFrequentAbsences({
    required String classId,
    required int minAbsences,
    required DateTime since,
    String? schoolId,
  }) async {
    final sinceStr = since.toIso8601String().split('T')[0];

    final params = {
      'p_class_id': classId,
      'p_min_absences': minAbsences,
      'p_since': sinceStr,
    };

    if (schoolId != null && schoolId.isNotEmpty) {
      params['p_school_id'] = schoolId;
    }

    final response = await _supabase.rpc('get_frequent_absences', params: params);
    return (response as List).cast<Map<String, dynamic>>();
  }

  // ============================================================
  // ABSENCES DU JOUR
  // ============================================================
  Future<List<Map<String, dynamic>>> getTodayAbsences(String schoolId) async {
    if (schoolId.isEmpty) throw Exception('schoolId requis');

    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _supabase
        .from('attendance')
        .select('''
          id,
          student_id,
          status,
          schedule_id,
          students!inner(id, first_name, last_name, class_id, classes(name)),
          schedules!inner(id, course_name, start_time)
        ''')
        .eq('school_id', schoolId)
        .eq('date', today)
        .neq('status', 'present');

    return (response as List).cast<Map<String, dynamic>>();
  }

  // ============================================================
  // HELPERS PRIVÉS
  // ============================================================
  static AttendanceStatus _parseStatus(String value) {
    switch (value) {
      case 'present': return AttendanceStatus.present;
      case 'absent': return AttendanceStatus.absent;
      case 'late': return AttendanceStatus.late;
      default: return AttendanceStatus.present;
    }
  }

  String _buildNotificationMessage(
    String firstName,
    String lastName,
    String? className,
    String? courseName,
    DateTime date,
  ) {
    final buffer = StringBuffer();
    buffer.write('$firstName $lastName');
    if (className != null) buffer.write(' (Classe: $className)');
    buffer.write(' a été marqué(e) absent(e)');
    if (courseName != null) buffer.write(' au cours de $courseName');
    buffer.write(' le ${_formatDate(date)}');
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}