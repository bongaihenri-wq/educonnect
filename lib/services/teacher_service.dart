import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherService {
  final SupabaseClient _client;

  TeacherService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  // OBJECTIF 1 : Récupérer les classes assignées au prof
  Future<List<Map<String, dynamic>>> getTeacherAssignments(String teacherId) async {
    final response = await _client
        .from('schedules')
        .select('*, classes(name), subjects(name)')
        .eq('teacher_id', teacherId)
        .order('day_of_week')
        .order('start_time');

    return response.map((s) => {
      'classId': s['class_id'],
      'className': s['classes']?['name'] ?? 'Sans nom',
      'subject': s['subjects']?['name'] ?? 'Sans matière',
      'startTime': s['start_time'],
      'endTime': s['end_time'],
      'dayOfWeek': s['day_of_week'],
    }).toList();
  }

  // OBJECTIF 2 : Récupérer les élèves d'une classe spécifique
  Future<List<Map<String, dynamic>>> getStudentsByClass(String classId) async {
    try {
      final response = await _client
          .from('students')
          .select('id, first_name, last_name, matricule')
          .eq('class_id', classId)
          .order('last_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des élèves: $e');
    }
  }

  // OBJECTIF 3 : Enregistrer l'appel en masse (Bulk Insert)
  Future<void> saveAttendance(List<Map<String, dynamic>> records) async {
    try {
      await _client.from('attendances').insert(records);
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement de l\'appel: $e');
    }
  }

  // ✅ CORRIGÉ : getTeacherSchedule avec _client + classes(name, level)
  Future<List<Map<String, dynamic>>> getTeacherSchedule({
    required String teacherId,
    required String schoolId,
  }) async {
    final response = await _client
        .from('schedules')
        .select('''
          id,
          class_id,
          classes(name, level),
          subject_id,
          subjects(name),
          day_of_week,
          start_time,
          end_time,
          room,
          school_id
        ''')
        .eq('teacher_id', teacherId)
        .eq('school_id', schoolId)
        .order('day_of_week', ascending: true)
        .order('start_time', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}