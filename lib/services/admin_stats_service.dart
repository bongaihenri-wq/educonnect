// lib/services/admin_stats_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStatsService {
  static final AdminStatsService _instance = AdminStatsService._internal();
  factory AdminStatsService() => _instance;
  AdminStatsService._internal();

  final _client = Supabase.instance.client;

  /// Récupère toutes les stats d'une école
  Future<Map<String, dynamic>> getSchoolStats(String schoolId) async {
    try {
      // 1. Compter les élèves
      final studentsResponse = await _client
          .from('students')
          .select('id')
          .eq('school_id', schoolId);
      final studentsCount = studentsResponse.length;

      // 2. Compter les classes
      final classesResponse = await _client
          .from('classes')
          .select('id')
          .eq('school_id', schoolId);
      final classesCount = classesResponse.length;

      // 3. Compter les enseignants (CORRIGÉ - via app_users direct + role)
      int teachersCount = 0;
      try {
        final teachersResponse = await _client
            .from('app_users')
            .select('id')
            .eq('school_id', schoolId)
            .eq('role', 'teacher');
        teachersCount = teachersResponse.length;
      } catch (e) {
        // Fallback via user_roles
        try {
          final teachersResponse = await _client
              .from('user_roles')
              .select('user_id')
              .eq('school_id', schoolId)
              .eq('is_active', true);
          
          // Filtrer manuellement les teachers
          final roleIds = teachersResponse.map((r) => r['user_id']).toList();
          if (roleIds.isNotEmpty) {
            final usersResponse = await _client
                .from('app_users')
                .select('id, role')
                .inFilter('id', roleIds);
            teachersCount = usersResponse.where((u) => u['role'] == 'teacher').length;
          }
        } catch (e2) {
          print('⚠️ Fallback teachers aussi en erreur: $e2');
        }
      }

      // 4. Parents : compter via app_users avec role='parent'
      int parentsCount = 0;
      try {
        final parentsResponse = await _client
            .from('app_users')
            .select('id')
            .eq('school_id', schoolId)
            .eq('role', 'parent');
        parentsCount = parentsResponse.length;
      } catch (e) {
        // Fallback: compter les students avec parent_id non null
        try {
          final studentsWithParent = await _client
              .from('students')
              .select('parent_id')
              .eq('school_id', schoolId)
              .not('parent_id', 'is', null);
          final parentIds = studentsWithParent
              .map((s) => s['parent_id'])
              .where((id) => id != null)
              .toSet();
          parentsCount = parentIds.length;
        } catch (e2) {
          print('⚠️ Fallback parents aussi en erreur: $e2');
        }
      }

      // 5. Stats de présence globale
      Map<String, dynamic> attendanceStats;
      try {
        attendanceStats = await _client
            .rpc('get_school_attendance_stats', params: {'p_school_id': schoolId});
      } catch (e) {
        final attendanceResponse = await _client
            .from('attendance')
            .select('status')
            .eq('school_id', schoolId);
        
        int total = attendanceResponse.length;
        int present = 0;
        int absent = 0;
        int late = 0;
        for (var a in attendanceResponse) {
          final status = a['status']?.toString() ?? '';
          if (status == 'present') present++;
          else if (status == 'absent') absent++;
          else if (status == 'late') late++;
        }
        
        attendanceStats = {
          'present_rate': total > 0 ? (present / total * 100).round() : 0,
          'absent_rate': total > 0 ? (absent / total * 100).round() : 0,
          'late_rate': total > 0 ? (late / total * 100).round() : 0,
        };
      }

      // 6. Moyenne générale des notes
      double averageGrade = 0;
      try {
        final allGrades = await _client
            .from('grades')
            .select('score')
            .eq('school_id', schoolId);

        if (allGrades.isNotEmpty) {
          final values = allGrades
              .map((g) => (g['score'] as num?)?.toDouble() ?? 0.0)
              .toList();
          if (values.isNotEmpty) {
            averageGrade = values.reduce((a, b) => a + b) / values.length;
          }
        }
      } catch (e) {
        print('⚠️ Erreur calcul moyenne: $e');
      }

      return {
        'students': studentsCount,
        'classes': classesCount,
        'teachers': teachersCount,
        'parents': parentsCount,
        'attendance': attendanceStats,
        'average_grade': averageGrade.toStringAsFixed(2),
        'loading': false,
        'error': null,
      };
    } catch (e) {
      print('❌ Erreur getSchoolStats: $e');
      return {
        'students': 0,
        'classes': 0,
        'teachers': 0,
        'parents': 0,
        'attendance': {'present_rate': 0, 'absent_rate': 0, 'late_rate': 0},
        'average_grade': '0.00',
        'loading': false,
        'error': e.toString(),
      };
    }
  }

  /// Récupère les classes avec stats détaillées (CORRIGÉ - sans duplication)
  Future<List<Map<String, dynamic>>> getClassesWithStats(String schoolId) async {
    try {
      final response = await _client
          .from('classes')
          .select('''
            id,
            name,
            level,
            students:students(
              id,
              first_name,
              last_name,
              matricule,
              gender
            ),
            schedules:schedules(
              id,
              day_of_week,
              start_time,
              end_time,
              subjects(name),
              app_users(first_name, last_name)
            )
          ''')
          .eq('school_id', schoolId)
          .order('level')
          .order('name');

      final classes = List<Map<String, dynamic>>.from(response);

      for (var classe in classes) {
        final students = classe['students'] as List<dynamic>? ?? [];
        final schedules = classe['schedules'] as List<dynamic>? ?? [];

        int boys = 0;
        int girls = 0;
        for (var s in students) {
          final gender = s['gender']?.toString().toLowerCase() ?? '';
          if (gender == 'm' || gender == 'male' || gender == 'masculin') boys++;
          else if (gender == 'f' || gender == 'female' || gender == 'feminin') girls++;
        }

        // Notes
        double avgGrade = 0;
        try {
          final allGrades = await _client
              .from('grades')
              .select('score')
              .eq('class_id', classe['id'])
              .eq('school_id', schoolId);

          if (allGrades.isNotEmpty) {
            final values = allGrades
                .map((g) => (g['score'] as num?)?.toDouble() ?? 0.0)
                .toList();
            if (values.isNotEmpty) {
              avgGrade = values.reduce((a, b) => a + b) / values.length;
            }
          }
        } catch (e) {
          print('⚠️ Erreur notes classe ${classe['id']}: $e');
        }

        // Présence avec comptage précis P/A/R
        final attendanceResponse = await _client
            .from('attendance')
            .select('status')
            .eq('class_id', classe['id'])
            .eq('school_id', schoolId);

        int present = 0;
        int absent = 0;
        int late = 0;
        int total = attendanceResponse.length;

        for (var a in attendanceResponse) {
          final status = a['status']?.toString() ?? '';
          if (status == 'present') present++;
          else if (status == 'absent') absent++;
          else if (status == 'late') late++;
        }

        // Calculer les pourcentages pour le graphique cumulé
        final presentRate = total > 0 ? (present / total * 100) : 0;
        final absentRate = total > 0 ? (absent / total * 100) : 0;
        final lateRate = total > 0 ? (late / total * 100) : 0;

        classe['stats'] = {
          'total_students': students.length,
          'boys': boys,
          'girls': girls,
          'total_schedules': schedules.length,
          'average_grade': avgGrade.toStringAsFixed(2),
          'presence_rate': total > 0 ? (present / total * 100).round() : 0,
          'present_count': present,
          'absent_count': absent,
          'late_count': late,
          'present_rate_pct': presentRate,
          'absent_rate_pct': absentRate,
          'late_rate_pct': lateRate,
          'total_attendance': total,
        };
      }

      return classes;
    } catch (e) {
      print('❌ Erreur getClassesWithStats: $e');
      return [];
    }
  }

  /// Récupère les stats des enseignants avec graphique cumulé
  Future<List<Map<String, dynamic>>> getTeachersWithAttendanceStats(String schoolId) async {
    try {
      // Récupérer les enseignants
      final teachersResponse = await _client
          .from('app_users')
          .select('id, first_name, last_name, email, phone')
          .eq('school_id', schoolId)
          .eq('role', 'teacher');

      final teachers = List<Map<String, dynamic>>.from(teachersResponse);
      final result = <Map<String, dynamic>>[];

      final thirtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String();

      for (var teacher in teachers) {
        final teacherId = teacher['id'] as String;

        // Stats d'appels ce mois
        final callsResponse = await _client
            .from('attendance')
            .select('id, status')
            .eq('school_id', schoolId)
            .eq('teacher_id', teacherId)
            .gte('date', thirtyDaysAgo);

        int callsThisMonth = callsResponse.length;
        int lateCalls = 0;
        int onTimeCalls = 0;

        for (var call in callsResponse) {
          final status = call['status']?.toString() ?? '';
          if (status == 'late') lateCalls++;
          else onTimeCalls++;
        }

        // Présence des élèves dans les cours de cet enseignant
        final studentAttendanceResponse = await _client
            .from('attendance')
            .select('status')
            .eq('school_id', schoolId)
            .eq('teacher_id', teacherId);

        int present = 0;
        int absent = 0;
        int late = 0;
        int totalStudentRecords = studentAttendanceResponse.length;

        for (var a in studentAttendanceResponse) {
          final status = a['status']?.toString() ?? '';
          if (status == 'present') present++;
          else if (status == 'absent') absent++;
          else if (status == 'late') late++;
        }

        // Pourcentages pour graphique cumulé
        final presentRate = totalStudentRecords > 0 ? (present / totalStudentRecords * 100) : 0;
        final absentRate = totalStudentRecords > 0 ? (absent / totalStudentRecords * 100) : 0;
        final lateRate = totalStudentRecords > 0 ? (late / totalStudentRecords * 100) : 0;

        // Cours programmés
        final schedulesResponse = await _client
            .from('schedules')
            .select('id')
            .eq('school_id', schoolId)
            .eq('teacher_id', teacherId);
        final scheduledCourses = schedulesResponse.length;

        result.add({
          'teacher_id': teacherId,
          'teacher_name': '${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}'.trim(),
          'email': teacher['email'],
          'phone': teacher['phone'],
          'calls_this_month': callsThisMonth,
          'late_calls': lateCalls,
          'on_time_calls': onTimeCalls,
          'scheduled_courses': scheduledCourses,
          'total_student_records': totalStudentRecords,
          'present_count': present,
          'absent_count': absent,
          'late_count': late,
          'present_rate_pct': presentRate,
          'absent_rate_pct': absentRate,
          'late_rate_pct': lateRate,
          'student_presence_rate': totalStudentRecords > 0 ? (present / totalStudentRecords * 100).round() : 0,
        });
      }

      return result;
    } catch (e) {
      print('❌ Erreur getTeachersWithAttendanceStats: $e');
      return [];
    }
  }

  /// Récupère l'assiduité par classe (CORRIGÉ - pour graphique cumulé)
  Future<List<Map<String, dynamic>>> getAttendanceByClass(
    String schoolId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final classesResponse = await _client
          .from('classes')
          .select('id, name, level')
          .eq('school_id', schoolId)
          .order('level')
          .order('name');

      final classes = List<Map<String, dynamic>>.from(classesResponse);
      final result = <Map<String, dynamic>>[];

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      for (var classe in classes) {
        final classId = classe['id'] as String;

        final attendanceResponse = await _client
            .from('attendance')
            .select('status')
            .eq('school_id', schoolId)
            .eq('class_id', classId)
            .gte('date', start.toIso8601String())
            .lte('date', end.toIso8601String());

        int total = attendanceResponse.length;
        int present = 0;
        int absent = 0;
        int late = 0;

        for (var a in attendanceResponse) {
          final status = a['status']?.toString() ?? '';
          if (status == 'present') present++;
          else if (status == 'absent') absent++;
          else if (status == 'late') late++;
        }

        // Pourcentages pour graphique cumulé 100%
        final presentRate = total > 0 ? (present / total * 100) : 0;
        final absentRate = total > 0 ? (absent / total * 100) : 0;
        final lateRate = total > 0 ? (late / total * 100) : 0;

        result.add({
          'class_id': classId,
          'class_name': '${classe['level']} ${classe['name']}',
          'presence_rate': total > 0 ? (present / total * 100).round() : 0,
          'present_count': present,
          'absent_count': absent,
          'late_count': late,
          'total_records': total,
          'present_rate_pct': presentRate,
          'absent_rate_pct': absentRate,
          'late_rate_pct': lateRate,
        });
      }

      return result;
    } catch (e) {
      print('❌ Erreur getAttendanceByClass: $e');
      return [];
    }
  }

  /// Récupère les notes par élève pour une classe
  Future<List<Map<String, dynamic>>> getGradesByClass(
    String schoolId,
    String classId,
  ) async {
    try {
      final studentsResponse = await _client
          .from('students')
          .select('id, first_name, last_name, matricule')
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .order('last_name');

      final students = List<Map<String, dynamic>>.from(studentsResponse);
      final result = <Map<String, dynamic>>[];

      for (var student in students) {
        final studentId = student['id'] as String;

        final studentGrades = await _client
            .from('grades')
            .select('score, subjects(name)')
            .eq('school_id', schoolId)
            .eq('student_id', studentId);

        final attendanceResponse = await _client
            .from('attendance')
            .select('status')
            .eq('school_id', schoolId)
            .eq('student_id', studentId);

        int total = attendanceResponse.length;
        int present = 0;
        int absent = 0;
        int late = 0;

        for (var a in attendanceResponse) {
          final status = a['status']?.toString() ?? '';
          if (status == 'present') present++;
          else if (status == 'absent') absent++;
          else if (status == 'late') late++;
        }

        double average = 0;
        if (studentGrades.isNotEmpty) {
          final values = studentGrades
              .map((g) => (g['score'] as num?)?.toDouble() ?? 0.0)
              .toList();
          if (values.isNotEmpty) {
            average = values.reduce((a, b) => a + b) / values.length;
          }
        }

        result.add({
          'student_id': studentId,
          'student_name': '${student['first_name']} ${student['last_name']}',
          'matricule': student['matricule'],
          'average_grade': average.toStringAsFixed(2),
          'grades_count': studentGrades.length,
          'presence_rate': total > 0 ? (present / total * 100).round() : 0,
          'absent_count': absent,
          'late_count': late,
        });
      }

      return result;
    } catch (e) {
      print('❌ Erreur getGradesByClass: $e');
      return [];
    }
  }
}