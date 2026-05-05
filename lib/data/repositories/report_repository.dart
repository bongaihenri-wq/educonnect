// lib/data/repositories/report_repository.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_period_model.dart';

// ============================================================
// ENUMS ET MODÈLES
// ============================================================

enum AttendanceDayStatus {
  present,
  absent,
  late;

  Color get color {
    switch (this) {
      case present: return Colors.green;
      case absent: return Colors.red;
      case late: return Colors.orange;
    }
  }

  String get emoji {
    switch (this) {
      case present: return '✅';
      case absent: return '❌';
      case late: return '⏰';
    }
  }
}

class ClassAttendanceStats {
  final int totalAbsences;
  final double classPresenceRate;
  final List<AbsentStudent> topAbsentStudents;
  final List<DailyAttendance> dailyAttendance;

  ClassAttendanceStats({
    required this.totalAbsences,
    required this.classPresenceRate,
    required this.topAbsentStudents,
    this.dailyAttendance = const [],
  });
}

class AbsentStudent {
  final String studentId;
  final String studentName;
  final int absenceCount;
  final int lateCount;

  AbsentStudent({
    required this.studentId,
    required this.studentName,
    required this.absenceCount,
    this.lateCount = 0,
  });
}

class DailyAttendance {
  final String date;
  final int present;
  final int absent;
  final int late;
  final DateTime? dateTime;
  final AttendanceDayStatus? status;
  final String? dayName;
  final String? timeRange;
  final String? courseName;
  final String? room;

  DailyAttendance({
    required this.date,
    required this.present,
    required this.absent,
    required this.late,
    this.dateTime,
    this.status,
    this.dayName,
    this.timeRange,
    this.courseName,
    this.room,
  });
}

class ClassGradeStats {
  final List<GradeInfo> grades;
  final double classAverage;

  ClassGradeStats({
    required this.grades,
    this.classAverage = 0.0,
  });

  Map<String, double?> get averageByType {
    final Map<String, List<double>> byType = {};
    for (final g in grades) {
      byType.putIfAbsent(g.type, () => []);
      byType[g.type]!.add(g.outOf > 0 ? (g.value / g.outOf) * 20 : 0);
    }
    return {
      for (var entry in byType.entries)
        entry.key: entry.value.isNotEmpty ? entry.value.reduce((a, b) => a + b) / entry.value.length : null
    };
  }

  int get above15Count => grades.where((g) {
    final pct = g.outOf > 0 ? (g.value / g.outOf) * 20 : 0;
    return pct > 15;
  }).length;

  int get between12And15Count => grades.where((g) {
    final pct = g.outOf > 0 ? (g.value / g.outOf) * 20 : 0;
    return pct >= 12 && pct <= 15;
  }).length;

  int get between10And12Count => grades.where((g) {
    final pct = g.outOf > 0 ? (g.value / g.outOf) * 20 : 0;
    return pct >= 10 && pct < 12;
  }).length;

  int get below10Count => grades.where((g) {
    final pct = g.outOf > 0 ? (g.value / g.outOf) * 20 : 0;
    return pct < 10;
  }).length;
}

class GradeInfo {
  final String studentId;
  final String studentName;
  final String type;
  final DateTime date;
  final double value;
  final double outOf;
  final int coefficient;

  GradeInfo({
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.date,
    required this.value,
    required this.outOf,
    this.coefficient = 1,
  });
}

class AttendanceStats {
  final double presenceRate;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final List<DailyAttendance> dailyBreakdown;

  AttendanceStats({
    required this.presenceRate,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.dailyBreakdown,
  });

  int get presentCount => presentDays;
  int get absentCount => absentDays;
  int get lateCount => lateDays;
}

class GradeStats {
  final List<GradeInfo> grades;
  final double average;

  GradeStats({
    required this.grades,
    this.average = 0.0,
  });

  double? get minGrade => grades.isNotEmpty ? grades.map((g) => g.value).reduce((a, b) => a < b ? a : b) : null;
  double? get maxGrade => grades.isNotEmpty ? grades.map((g) => g.value).reduce((a, b) => a > b ? a : b) : null;
}

// ============================================================
// REPOSITORY
// ============================================================

class ReportRepository {
  final SupabaseClient _supabase;

  ReportRepository({SupabaseClient? supabase}) 
      : _supabase = supabase ?? Supabase.instance.client;

  // ============================================================
  // STATS CLASSE — PRÉSENCES
  // ============================================================
  Future<ClassAttendanceStats> getClassAttendanceStats({
    required String classId,
    required String teacherId,
    required String subject,
    required ReportPeriodModel period,
  }) async {
    final startStr = period.startDate.toIso8601String().split('T')[0];
    final endStr = period.endDate.toIso8601String().split('T')[0];

    // 1. Récupérer les élèves
    final studentsResponse = await _supabase
        .from('students')
        .select('id, first_name, last_name')
        .eq('class_id', classId);

    final students = (studentsResponse as List).cast<Map<String, dynamic>>();
    final Map<String, String> studentNames = {
      for (var s in students) 
        s['id'] as String: '${s['first_name']} ${s['last_name']}'
    };

    // 2. Récupérer les présences
    var query = _supabase
        .from('attendance')
        .select('student_id, date, status')
        .eq('class_id', classId)
        .gte('date', startStr)
        .lte('date', endStr);

    if (teacherId.isNotEmpty) {
      query = query.eq('teacher_id', teacherId);
    }

    final response = await query.order('date', ascending: true);
    final records = (response as List).cast<Map<String, dynamic>>();

    // Calculs par élève et par jour
    final Map<String, Map<String, int>> studentCounts = {};
    final Map<String, Map<String, int>> dailyCounts = {};

    for (final record in records) {
      final studentId = record['student_id'] as String;
      final date = record['date'] as String;
      final status = record['status'] as String;

      studentCounts.putIfAbsent(studentId, () => {'present': 0, 'absent': 0, 'late': 0, 'total': 0});
      studentCounts[studentId]![status] = (studentCounts[studentId]![status] ?? 0) + 1;
      studentCounts[studentId]!['total'] = (studentCounts[studentId]!['total'] ?? 0) + 1;

      dailyCounts.putIfAbsent(date, () => {'present': 0, 'absent': 0, 'late': 0});
      dailyCounts[date]![status] = (dailyCounts[date]![status] ?? 0) + 1;
    }

    // Top absences
    final absentStudents = studentCounts.entries
        .where((e) => (e.value['absent'] ?? 0) > 0)
        .map((e) => AbsentStudent(
              studentId: e.key,
              studentName: studentNames[e.key] ?? 'Élève inconnu',
              absenceCount: e.value['absent'] ?? 0,
              lateCount: e.value['late'] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.absenceCount.compareTo(a.absenceCount));

    // Données journalières (vue classe)
    final dailyData = dailyCounts.entries.map((e) {
      final date = e.key;
      final dateTime = DateTime.parse(date);
      final dayNames = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      
      AttendanceDayStatus dayStatus;
      if ((e.value['present'] ?? 0) > 0) dayStatus = AttendanceDayStatus.present;
      else if ((e.value['late'] ?? 0) > 0) dayStatus = AttendanceDayStatus.late;
      else dayStatus = AttendanceDayStatus.absent;

      return DailyAttendance(
        date: '${date.substring(8, 10)}/${date.substring(5, 7)}',
        present: e.value['present'] ?? 0,
        absent: e.value['absent'] ?? 0,
        late: e.value['late'] ?? 0,
        dateTime: dateTime,
        status: dayStatus,
        dayName: dayNames[dateTime.weekday - 1],
        timeRange: '--:--',
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalRecords = records.length;
    final presentCount = records.where((r) => r['status'] == 'present').length;
    final presenceRate = totalRecords > 0 ? (presentCount / totalRecords * 100) : 0.0;

    return ClassAttendanceStats(
      totalAbsences: absentStudents.fold(0, (sum, s) => sum + s.absenceCount),
      classPresenceRate: presenceRate,
      topAbsentStudents: absentStudents.take(5).toList(),
      dailyAttendance: dailyData,
    );
  }

  // ============================================================
  // STATS CLASSE — NOTES
  // ============================================================
  Future<ClassGradeStats> getClassGradeStats({
    required String classId,
    required String teacherId,
    required String subject,
    required ReportPeriodModel period,
  }) async {
    final startStr = period.startDate.toIso8601String().split('T')[0];
    final endStr = period.endDate.toIso8601String().split('T')[0];

    var query = _supabase
        .from('grades')
        .select('''
          student_id,
          type,
          score,
          max_score,
          coefficient,
          comment,
          date,
          students!inner(first_name, last_name)
        ''')
        .eq('class_id', classId)
        .gte('date', startStr)
        .lte('date', endStr);

    if (teacherId.isNotEmpty) {
      query = query.eq('teacher_id', teacherId);
    }
    if (subject != 'all') {
      query = query.eq('subject_id', subject);
    }

    final response = await query.order('date', ascending: false);
    final records = (response as List).cast<Map<String, dynamic>>();

    final grades = records.map((r) {
      final student = r['students'] as Map<String, dynamic>;
      final dateStr = r['date'] as String;
      final date = DateTime.parse(dateStr);

      return GradeInfo(
        studentId: r['student_id'] as String,
        studentName: '${student['first_name']} ${student['last_name']}',
        type: r['type'] as String,
        date: date,
        value: (r['score'] as num).toDouble(),
        outOf: (r['max_score'] as num).toDouble(),
        coefficient: r['coefficient'] as int? ?? 1,
      );
    }).toList();

    double classAvg = 0.0;
    if (grades.isNotEmpty) {
      final normalized = grades.map((g) => g.outOf > 0 ? (g.value / g.outOf) * 20 : 0.0).toList();
      classAvg = normalized.reduce((a, b) => a + b) / normalized.length;
    }

    return ClassGradeStats(
      grades: grades,
      classAverage: classAvg,
    );
  }

  // ============================================================
  // STATS ÉLÈVE — PRÉSENCES (DOUBLE REQUÊTE : attendance + schedules + subjects)
  // ============================================================
  Future<AttendanceStats> getStudentAttendanceStats({
    required String studentId,
    required String classId,
    required String teacherId,
    required String subject,
    required ReportPeriodModel period,
  }) async {
    final startStr = period.startDate.toIso8601String().split('T')[0];
    final endStr = period.endDate.toIso8601String().split('T')[0];

    // ✅ ÉTAPE 1 : Récupérer les présences (avec schedule_id)
    var query = _supabase
        .from('attendance')
        .select('date, status, schedule_id')
        .eq('student_id', studentId)
        .eq('class_id', classId)
        .gte('date', startStr)
        .lte('date', endStr);

    if (teacherId.isNotEmpty) {
      query = query.eq('teacher_id', teacherId);
    }

    final attendanceResponse = await query.order('date', ascending: true);
    final records = (attendanceResponse as List).cast<Map<String, dynamic>>();

    // ✅ ÉTAPE 2 : Récupérer les schedules + subjects (noms des matières)
    final scheduleIds = records
        .map((r) => r['schedule_id'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .toList();

    Map<String, Map<String, dynamic>> schedulesMap = {};
    Map<String, String> subjectNamesMap = {}; // ✅ NOUVEAU

    if (scheduleIds.isNotEmpty) {
      try {
        // 2a. Schedules (récupère subject_id au lieu de course_name)
        final schedulesResponse = await _supabase
            .from('schedules')
            .select('id, subject_id, start_time, end_time, room')
            .inFilter('id', scheduleIds);

        for (final s in schedulesResponse as List) {
          schedulesMap[s['id'] as String] = s as Map<String, dynamic>;
        }

        // 2b. Subjects - récupérer les noms des matières
        final subjectIds = schedulesMap.values
            .map((s) => s['subject_id'] as String?)
            .where((id) => id != null && id.isNotEmpty)
            .toSet()
            .toList();

        if (subjectIds.isNotEmpty) {
          final subjectsResponse = await _supabase
              .from('subjects')
              .select('id, name')
              .inFilter('id', subjectIds);

          for (final sub in subjectsResponse as List) {
            subjectNamesMap[sub['id'] as String] = sub['name'] as String;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur récupération schedules/subjects: $e');
      }
    }

    final presentDays = records.where((r) => r['status'] == 'present').length;
    final absentDays = records.where((r) => r['status'] == 'absent').length;
    final lateDays = records.where((r) => r['status'] == 'late').length;
    final totalDays = records.length;

    // ✅ FORMAT HEURE SANS SECONDES
    String formatTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return '--:--';
      final parts = timeStr.split(':');
      if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
      return timeStr;
    }

    // ✅ ÉTAPE 3 : Créer DailyAttendance avec vraies données
    final dailyBreakdown = records.map((r) {
      final dateStr = r['date'] as String;
      final date = DateTime.parse(dateStr);
      final status = r['status'] as String;
      final scheduleId = r['schedule_id'] as String?;
      final schedule = scheduleId != null ? schedulesMap[scheduleId] : null;
      final subjectId = schedule?['subject_id'] as String?;

      AttendanceDayStatus dayStatus;
      if (status == 'present') dayStatus = AttendanceDayStatus.present;
      else if (status == 'late') dayStatus = AttendanceDayStatus.late;
      else dayStatus = AttendanceDayStatus.absent;

      // Format date court : "23/04"
      final dateShort = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

      // ✅ NOM MATIÈRE depuis subjects via subject_id
      final courseName = subjectId != null ? subjectNamesMap[subjectId] : null;

      // ✅ HEURES sans secondes
      final startTime = formatTime(schedule?['start_time'] as String?);
      final endTime = formatTime(schedule?['end_time'] as String?);
      final room = schedule?['room'] as String? ?? '';

      return DailyAttendance(
        date: dateShort,
        present: status == 'present' ? 1 : 0,
        absent: status == 'absent' ? 1 : 0,
        late: status == 'late' ? 1 : 0,
        dateTime: date,
        status: dayStatus,
        dayName: '',
        timeRange: '$startTime - $endTime',
        courseName: courseName ?? 'Cours',
        room: room,
      );
    }).toList();

    return AttendanceStats(
      presenceRate: totalDays > 0 ? (presentDays / totalDays * 100) : 0.0,
      totalDays: totalDays,
      presentDays: presentDays,
      absentDays: absentDays,
      lateDays: lateDays,
      dailyBreakdown: dailyBreakdown,
    );
  }

  // ============================================================
  // STATS ÉLÈVE — NOTES
  // ============================================================
  Future<GradeStats> getStudentGradeStats({
    required String studentId,
    required String classId,
    required String teacherId,
    required String subject,
    required ReportPeriodModel period,
  }) async {
    final startStr = period.startDate.toIso8601String().split('T')[0];
    final endStr = period.endDate.toIso8601String().split('T')[0];

    var query = _supabase
        .from('grades')
        .select('type, score, max_score, coefficient, comment, date')
        .eq('student_id', studentId)
        .eq('class_id', classId)
        .gte('date', startStr)
        .lte('date', endStr);

    if (teacherId.isNotEmpty) {
      query = query.eq('teacher_id', teacherId);
    }
    if (subject != 'all') {
      query = query.eq('subject_id', subject);
    }

    final response = await query.order('date', ascending: false);
    final records = (response as List).cast<Map<String, dynamic>>();

    final grades = records.map((r) {
      final dateStr = r['date'] as String;
      return GradeInfo(
        studentId: studentId,
        studentName: '',
        type: r['type'] as String,
        date: DateTime.parse(dateStr),
        value: (r['score'] as num).toDouble(),
        outOf: (r['max_score'] as num).toDouble(),
        coefficient: r['coefficient'] as int? ?? 1,
      );
    }).toList();

    double avg = 0.0;
    if (grades.isNotEmpty) {
      double weightedSum = 0.0;
      int totalCoef = 0;
      for (final g in grades) {
        final normalized = g.outOf > 0 ? (g.value / g.outOf) * 20 : 0.0;
        weightedSum += normalized * g.coefficient;
        totalCoef += g.coefficient;
      }
      avg = totalCoef > 0 ? weightedSum / totalCoef : 0.0;
    }

    return GradeStats(grades: grades, average: avg);
  }

  // ============================================================
  // COMMENTAIRES
  // ============================================================
  Future<void> addComment({
    required String studentId,
    required String classId,
    required String schoolId,
    required String teacherId,
    required String subject,
    required ReportPeriodModel period,
    required String comment,
  }) async {
    await _supabase.from('comments').insert({
      'student_id': studentId,
      'class_id': classId,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'subject': subject,
      'period_start': period.startDate.toIso8601String(),
      'period_end': period.endDate.toIso8601String(),
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}