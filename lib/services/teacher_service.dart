// lib/services/teacher_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherService {
  final SupabaseClient _supabase;

  TeacherService({SupabaseClient? supabase}) 
      : _supabase = supabase ?? Supabase.instance.client;

  // ============================================================
  // EXISTANT : Récupérer les enseignants de l'enfant
  // ============================================================
Future<List<Map<String, dynamic>>> getTeachersForStudent(String studentId) async {
  try {
    final studentData = await _supabase
        .from('students')
        .select('class_id')
        .eq('id', studentId)
        .single();

    final classId = studentData['class_id'] as String?;
    if (classId == null) return [];

    // ✅ CORRIGÉ : app_users au lieu de teachers
    final schedulesData = await _supabase
        .from('schedules')
        .select('''
          teacher_id,
          subject_id,
          subjects(id, name),
          app_users(id, first_name, last_name, email)
        ''')
        .eq('class_id', classId)
        .eq('is_active', true);

    final teachers = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final schedule in schedulesData as List) {
      final teacherId = schedule['teacher_id'] as String?;
      final subjectId = schedule['subject_id'] as String?;
      if (teacherId == null || subjectId == null) continue;

      final key = '${teacherId}_$subjectId';
      if (seen.contains(key)) continue;
      seen.add(key);

      final teacher = schedule['app_users'] as Map<String, dynamic>?; // ✅ CORRIGÉ
      final subject = schedule['subjects'] as Map<String, dynamic>?;

      if (teacher != null && subject != null) {
        teachers.add({
          'teacher_id': teacherId,
          'teacher_name': '${teacher['first_name']} ${teacher['last_name']}',
          'teacher_email': teacher['email'],
          'subject_id': subjectId,
          'subject_name': subject['name'],
        });
      }
    }

    return teachers;
  } catch (e) {
    print('❌ Erreur getTeachersForStudent: $e');
    return [];
  }
}

  // ============================================================
  // EXISTANT : Récupérer un enseignant spécifique par matière
  // ============================================================
  Future<Map<String, dynamic>?> getTeacherForSubject({
    required String classId,
    required String subjectName,
  }) async {
    try {
      final subjectData = await _supabase
          .from('subjects')
          .select('id')
          .eq('name', subjectName)
          .maybeSingle();

      if (subjectData == null) return null;
      final subjectId = subjectData['id'] as String;

      final scheduleData = await _supabase
          .from('schedules')
          .select('''
            teacher_id,
            teachers(id, first_name, last_name, email)
          ''')
          .eq('class_id', classId)
          .eq('subject_id', subjectId)
          .eq('is_active', true)
          .maybeSingle();

      if (scheduleData == null) return null;

      final teacher = scheduleData['teachers'] as Map<String, dynamic>?;
      if (teacher == null) return null;

      return {
        'teacher_id': scheduleData['teacher_id'] as String,
        'teacher_name': '${teacher['first_name']} ${teacher['last_name']}',
        'teacher_email': teacher['email'],
        'subject_id': subjectId,
        'subject_name': subjectName,
      };
    } catch (e) {
      print('❌ Erreur getTeacherForSubject: $e');
      return null;
    }
  }

  // ============================================================
  // RÉTABLI : Récupérer l'emploi du temps complet d'un enseignant
  // ============================================================
Future<List<Map<String, dynamic>>> getTeacherSchedule({
  required String teacherId,
  required String schoolId,
}) async {
  try {
    final response = await _supabase
        .from('schedules')
        .select('''
          id,
          day_of_week,
          start_time,
          end_time,
          room,
          is_active,
          subjects!inner(id, name),
          classes!inner(id, name, level)
        ''')
        .eq('teacher_id', teacherId)
        .eq('school_id', schoolId)
        .eq('is_active', true)
        .order('day_of_week', ascending: true)
        .order('start_time', ascending: true);

    // ✅ TRANSFORMER en champs plats pour fromJson
    final flattened = (response as List).map((item) {
      final subjects = item['subjects'] as Map<String, dynamic>?;
      final classes = item['classes'] as Map<String, dynamic>?;
      
      return {
        'id': item['id'],
        'day_of_week': item['day_of_week'],
        'start_time': item['start_time'],
        'end_time': item['end_time'],
        'room': item['room'],
        'is_active': item['is_active'],
        'subject_id': subjects?['id'],
        'subject_name': subjects?['name'],
        'class_id': classes?['id'],
        'class_name': classes?['name'],
        'level': classes?['level'],
        'school_id': schoolId,
      };
    }).toList();

    return flattened.cast<Map<String, dynamic>>();
  } catch (e) {
    print('❌ Erreur getTeacherSchedule: $e');
    return [];
  }
}

  // ============================================================
  // RÉTABLI : Récupérer les cours assignés à un enseignant
  // ============================================================
  Future<List<Map<String, dynamic>>> getTeacherAssignments(String teacherId) async {
    try {
      final response = await _supabase
          .from('schedules')
          .select('''
            id,
            day_of_week,
            start_time,
            end_time,
            room,
            subjects(id, name),
            classes(id, name, level, school_id)
          ''')
          .eq('teacher_id', teacherId)
          .eq('is_active', true)
          .order('day_of_week', ascending: true)
          .order('start_time', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Erreur getTeacherAssignments: $e');
      return [];
    }
  }

  // ============================================================
  // NOUVEAU : Récupérer les messages des parents pour un enseignant
  // ============================================================
  Future<List<Map<String, dynamic>>> getParentMessages({
    required String teacherId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('''
            id,
            content,
            sender_name,
            target_subject,
            is_broadcast,
            is_read,
            created_at,
            students(id, first_name, last_name, class_id, classes(name))
          ''')
          .eq('teacher_id', teacherId)
          .eq('recipient_type', 'teacher')
          .eq('is_archived', false)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Erreur getParentMessages: $e');
      return [];
    }
  }

  // ============================================================
  // NOUVEAU : Marquer un message comme lu
  // ============================================================
  Future<void> markMessageAsRead(String messageId) async {
    await _supabase.from('comments').update({
      'is_read': true,
    }).eq('id', messageId);
  }
}