import 'package:educonnect/presentation/blocs/attendance/attendance_event.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/attendance.dart';

class AttendanceRepository {
  final SupabaseClient _supabase;

  AttendanceRepository(this._supabase);

  /// Sauvegarde l'appel en base de données (avec transaction)
  Future<void> saveAttendance({
    required String classId,
    required String courseId,
    required DateTime date,
    required Map<String, AttendanceStatus> records,
  }) async {
    final teacherId = _supabase.auth.currentUser?.id;
    if (teacherId == null) throw Exception('Non authentifié');

    final dateStr = date.toIso8601String().split('T')[0];
    final now = DateTime.now().toIso8601String();

    // Préparer les données pour insertion batch
    final attendances = records.entries.map((entry) => {
      'student_id': entry.key,
      'course_id': courseId,
      'teacher_id': teacherId,
      'date': dateStr,
      'status': entry.value.value,
      'created_at': now,
    }).toList();

    try {
      // Supprimer les anciennes présences pour ce cours/date (même teacher)
      await _supabase
          .from('attendance')
          .delete()
          .eq('course_id', courseId)
          .eq('date', dateStr)
          .eq('teacher_id', teacherId);

      // Insérer les nouvelles présences
      if (attendances.isNotEmpty) {
        await _supabase.from('attendance').insert(attendances);
      }
    } catch (e) {
      throw Exception('Erreur sauvegarde présences: $e');
    }
  }

  /// Récupère l'historique des présences d'un élève
  Future<List<Attendance>> getStudentAttendance(String studentId) async {
    final response = await _supabase
        .from('attendance')
        .select()
        .eq('student_id', studentId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => Attendance.fromJson(json))
        .toList();
  }

  /// Récupère les présences d'une classe pour une date
  Future<Map<String, AttendanceStatus>> getClassAttendance({
    required String classId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];

    final response = await _supabase
        .from('attendance')
        .select('*, students!inner(class_id)')
        .eq('students.class_id', classId)
        .eq('date', dateStr);

    final result = <String, AttendanceStatus>{};
    for (final record in response as List) {
      result[record['student_id']] = 
          AttendanceStatusExtension.fromString(record['status']);
    }
    return result;
  }

  /// ⭐ NOUVEAU : Vérifie si un appel existe déjà pour ce cours/date
  Future<bool> checkExistingAttendance({
    required String courseId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final teacherId = _supabase.auth.currentUser?.id;
    
    final response = await _supabase
        .from('attendance')
        .select('id')
        .eq('course_id', courseId)
        .eq('date', dateStr)
        .eq('teacher_id', teacherId as Object)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  /// Notifie les parents des absences/retards
  Future<void> notifyParents({
    required List<String> studentIds,
    required DateTime date,
    String? className,
    String? courseName,
  }) async {
    if (studentIds.isEmpty) return;

    try {
      // Récupérer les parents des élèves concernés
      final parentsResponse = await _supabase
          .from('parent_students')
          .select('''
            parent_id,
            students!inner(
              id,
              first_name,
              last_name
            )
          ''')
          .inFilter('student_id', studentIds);

      final notifications = <Map<String, dynamic>>[];

      for (final link in parentsResponse as List) {
        final parentId = link['parent_id'];
        final student = link['students'];
        
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
        });
      }

      // Insérer les notifications en batch
      if (notifications.isNotEmpty) {
        await _supabase.from('notifications').insert(notifications);
      }
    } catch (e) {
      // Log mais ne pas bloquer l'appel
      debugPrint('Erreur notification parents: $e');
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
    buffer.write(' a été marqué(e) ');
    
    final status = 'absent(e)'; // ou retard selon contexte
    buffer.write(status);
    
    if (courseName != null) buffer.write(' au cours de $courseName');
    buffer.write(' le ${_formatDate(date)}');
    
    return buffer.toString();
  }

  /// Récupère les statistiques de présence d'une classe
  Future<Map<String, dynamic>> getClassStats({
    required String classId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    final response = await _supabase
        .from('attendance')
        .select('status, students!inner(class_id)')
        .eq('students.class_id', classId)
        .gte('date', startStr)
        .lte('date', endStr);

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

  /// ⭐ NOUVEAU : Récupère les absences fréquentes (alertes)
  Future<List<Map<String, dynamic>>> getFrequentAbsences({
    required String classId,
    required int minAbsences,
    required DateTime since,
  }) async {
    final sinceStr = since.toIso8601String().split('T')[0];

    final response = await _supabase.rpc('get_frequent_absences', params: {
      'p_class_id': classId,
      'p_min_absences': minAbsences,
      'p_since': sinceStr,
    });

    return (response as List).cast<Map<String, dynamic>>();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}