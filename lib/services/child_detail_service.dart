// lib/presentation/pages/parent/services/child_detail_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ✅ AJOUT : Imports pour retry et exceptions
import '/../../../services/retry_service.dart';

class ChildDetailService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // ✅ AJOUT : Service de retry
  final RetryService _retry = const RetryService();

  // ─── PRÉSENCES ─────────────────────────────
  Future<List<Map<String, dynamic>>> getAttendance(String studentId) async {
    // ✅ AJOUT : Retry automatique sur timeout/réseau
    return _retry.execute(() async {
      final response = await _supabase
          .from('attendance')
          .select('''
            date,
            status,
            schedule_id,
            schedules!inner(
              start_time,
              end_time,
              room,
              subjects(name)
            )
          ''')
          .eq('student_id', studentId)
          .order('date', ascending: false)
          .limit(30);

      return (response as List).cast<Map<String, dynamic>>();
    });
  }

  // ─── NOTES ─────────────────────────────────
  Future<List<Map<String, dynamic>>> getGrades(String studentId) async {
    return _retry.execute(() async {
      final response = await _supabase.from('grades').select('''
            score,
            max_score,
            coefficient,
            type,
            comment,
            date,
            subjects(name)
          ''').eq('student_id', studentId).order('date', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    });
  }

  // ─── EMPLOI DU TEMPS ─────────────────────
  Future<List<Map<String, dynamic>>> getTimetable(String studentId) async {
    return _retry.execute(() async {
      final student = await _supabase
          .from('students')
          .select('class_id')
          .eq('id', studentId)
          .single();

      final classId = student['class_id'] as String;

      final response = await _supabase
          .from('schedules')
          .select('''
            day_of_week,
            start_time,
            end_time,
            room,
            subjects(name),
            app_users(first_name, last_name)
        ''')
          .eq('class_id', classId)
          .eq('is_active', true)
          .order('day_of_week')
          .order('start_time');

      return (response as List).cast<Map<String, dynamic>>();
    });
  }

  // ─── COMMENTAIRES ────────────────────────
  Future<List<Map<String, dynamic>>> getComments(String studentId) async {
    return _retry.execute(() async {
      final response = await _supabase
          .from('comments')
          .select('''
            id,
            content,
            created_at,
            expires_at,
            teacher_id,
            recipients,
            parent_reply,
            replied_at
          ''')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((c) {
            final map = c as Map<String, dynamic>;
            return map;
          })
          .cast<Map<String, dynamic>>()
          .toList();
    });
  }

  // ─── STATS ───────────────────────────────
  Future<Map<String, dynamic>> getStats(String studentId) async {
    return _retry.execute(() async {
      final attendance = await getAttendance(studentId);
      final grades = await getGrades(studentId);

      final present = attendance.where((a) => a['status'] == 'present').length;
      final absent = attendance.where((a) => a['status'] == 'absent').length;
      final late = attendance.where((a) => a['status'] == 'late').length;

      double average = 0.0;
      if (grades.isNotEmpty) {
        double weightedSum = 0.0;
        int totalCoef = 0;
        for (final g in grades) {
          final score = (g['score'] as num).toDouble();
          final maxScore = (g['max_score'] as num?)?.toDouble() ?? 20.0;
          final coef = (g['coefficient'] as num?)?.toInt() ?? 1;
          final normalized = maxScore > 0 ? (score / maxScore) * 20 : 0.0;
          weightedSum += normalized * coef;
          totalCoef += coef;
        }
        average = totalCoef > 0 ? weightedSum / totalCoef : 0.0;
      }

      return {
        'present': present,
        'absent': absent,
        'late': late,
        'average': average,
      };
    });
  }

  // ─── ALERTES 24H ─────────────────────────
  Future<List<Map<String, dynamic>>> getRecentAlerts(String studentId) async {
    return _retry.execute(() async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final attendance = await _supabase
          .from('attendance')
          .select('date, status, schedules(start_time, subjects(name))')
          .eq('student_id', studentId)
          .gte('date',
              '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}')
          .order('date', ascending: false);

      final alerts = <Map<String, dynamic>>[];

      for (final a in attendance as List) {
        final status = a['status'] as String;
        if (status == 'present') continue;

        alerts.add({
          'type': status == 'absent' ? 'absence' : 'late',
          'message': status == 'absent'
              ? 'Absence en ${a['schedules']?['subjects']?['name'] ?? 'cours'}'
              : 'Retard en ${a['schedules']?['subjects']?['name'] ?? 'cours'}',
          'date': a['date'],
          'icon': status == 'absent' ? Icons.cancel : Icons.access_time,
          'color': status == 'absent' ? Colors.red : Colors.orange,
        });
      }

      return alerts;
    });
  }

  // ─── PROCHAIN COURS ──────────────────────
  Future<Map<String, dynamic>?> getNextClass(String studentId) async {
    return _retry.execute(() async {
      final now = DateTime.now();
      final today = now.weekday;
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

      final student = await _supabase
          .from('students')
          .select('class_id')
          .eq('id', studentId)
          .single();

      final classId = student['class_id'] as String;

      var response = await _supabase
          .from('schedules')
          .select('''
            start_time,
            end_time,
            room,
            subjects(name)
          ''')
          .eq('class_id', classId)
          .eq('day_of_week', today)
          .eq('is_active', true)
          .gt('start_time', currentTime)
          .order('start_time')
          .limit(1);

      if ((response as List).isEmpty) {
        final tomorrow = today == 7 ? 1 : today + 1;
        response = await _supabase
            .from('schedules')
            .select('''
              start_time,
              end_time,
              room,
              subjects(name)
            ''')
            .eq('class_id', classId)
            .eq('day_of_week', tomorrow)
            .eq('is_active', true)
            .order('start_time')
            .limit(1);
      }

      if ((response as List).isEmpty) return null;

      final course = response.first;
      return {
        'subject': course['subjects']?['name'] ?? 'Cours',
        'start_time': _formatTime(course['start_time']),
        'end_time': _formatTime(course['end_time']),
        'room': course['room'] ?? 'Salle non définie',
      };
    });
  }

  // ─── DEVOIRS ─────────────────────────────
  Future<List<Map<String, dynamic>>> getHomeworks(String studentId) async {
    return _retry.execute(() async {
      final studentResponse = await _supabase
          .from('students')
          .select('class_id')
          .eq('id', studentId)
          .single();

      final classId = studentResponse['class_id'];
      if (classId == null) return [];

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final dateFilter = '${sevenDaysAgo.year.toString().padLeft(4, '0')}-'
          '${sevenDaysAgo.month.toString().padLeft(2, '0')}-'
          '${sevenDaysAgo.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('homeworks')
          .select('''
            *,
            subjects(*),
            classes(*),
            teacher:teacher_id(id, first_name, last_name, role)
          ''')
          .eq('class_id', classId)
          .gte('due_date', dateFilter)
          .order('due_date', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    });
  }

  // ─── HELPER : Format heure HH:MM ────────────
  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    final parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeStr;
  }
}
