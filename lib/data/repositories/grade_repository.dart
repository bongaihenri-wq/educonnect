// lib/data/repositories/grade_repository.dart
import 'package:educonnect/data/models/grade_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GradeRepository {
  final SupabaseClient _supabase;

  GradeRepository(this._supabase);

  // ============================================================
  // SAUVEGARDE DES NOTES (Bulk Insert)
  // ============================================================
 Future<void> saveGrades({
  required String classId,
  required String subjectId,
  required String scheduleId,
  required String teacherId,
  required String schoolId,
  required String evaluationType,
  required String evaluationName,
  required DateTime date,
  required Map<String, double> scores,
  required double maxScore,
  int coefficient = 1, // ✅ PARAMÈTRE REÇU
}) async {
  
  print('🔥 COEFFICIENT REÇU: $coefficient'); // Debug

  final normalizedType = evaluationType.toLowerCase().trim();
  const validTypes = ['devoir', 'interro', 'examen', 'participation'];

  if (!validTypes.contains(normalizedType)) {
    throw Exception('Type "$evaluationType" invalide');
  }

  if (schoolId.isEmpty) throw Exception('schoolId requis');
  if (teacherId.isEmpty) throw Exception('teacherId requis');
  if (classId.isEmpty) throw Exception('classId requis');

  final now = DateTime.now().toIso8601String();

  final grades = scores.entries.map((entry) => {
    'student_id': entry.key,
    'class_id': classId,
    'subject_id': subjectId,
    'schedule_id': scheduleId.isNotEmpty ? scheduleId : null,
    'teacher_id': teacherId,
    'school_id': schoolId,
    'type': normalizedType,
    'score': entry.value,
    'max_score': maxScore,
    'coefficient': coefficient, // ✅ BIEN UTILISÉ ICI
    'comment': evaluationName,
    'date': date.toIso8601String().split('T')[0],
    'created_at': now,
  }).toList();

  try {
    // Delete existing
    await _supabase
        .from('grades')
        .delete()
        .eq('class_id', classId)
        .eq('subject_id', subjectId)
        .eq('teacher_id', teacherId)
        .eq('date', date.toIso8601String().split('T')[0])
        .eq('type', normalizedType)
        .eq('comment', evaluationName)
        .eq('school_id', schoolId);

    // Insert
    if (grades.isNotEmpty) {
      await _supabase.from('grades').insert(grades);
      debugPrint('✅ ${grades.length} notes sauvegardées (coef: $coefficient)');
    }
  } catch (e) {
    debugPrint('❌ Erreur sauvegarde notes: $e');
    throw Exception('Erreur sauvegarde notes: $e');
  }
}

  // ============================================================
  // RÉCUPÉRATION — Notes d'une classe/matière/date
  // ============================================================
  Future<Map<String, GradeModel>> getGradesForEvaluation({
    required String classId,
    required String subjectId,
    required String teacherId,
    required DateTime date,
    required String type,
    required String evaluationName,
    String? schoolId,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];

    var query = _supabase
        .from('grades')
        .select()  // ✅ Pas de colonnes spécifiques = PostgrestFilterBuilder
        .eq('class_id', classId)
        .eq('subject_id', subjectId)
        .eq('teacher_id', teacherId)
        .eq('date', dateStr)
        .eq('type', type)
        .eq('comment', evaluationName);

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }

    final response = await query;

    final result = <String, GradeModel>{};
    for (final record in response as List) {
      final grade = GradeModel.fromJson(record);
      result[grade.studentId] = grade;
    }
    return result;
  }

  // ============================================================
  // RÉCUPÉRATION — Toutes les notes d'un élève
  // ============================================================
  Future<List<GradeModel>> getStudentGrades(
    String studentId, {
    String? schoolId,
    String? subjectId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase
        .from('grades')
        .select()  // ✅ Pas de colonnes spécifiques
        .eq('student_id', studentId);

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      query = query.eq('subject_id', subjectId);
    }
    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('date', ascending: false);
    return (response as List)
        .map((json) => GradeModel.fromJson(json))
        .toList();
  }

  // ============================================================
  // MOYENNES — Par élève / matière / période
  // ============================================================
  Future<Map<String, dynamic>> getStudentAverage(
    String studentId, {
    String? subjectId,
    DateTime? startDate,
    DateTime? endDate,
    String? schoolId,
  }) async {
    final grades = await getStudentGrades(
      studentId,
      schoolId: schoolId,
      subjectId: subjectId,
      startDate: startDate,
      endDate: endDate,
    );

    if (grades.isEmpty) {
      return {'average': 0.0, 'count': 0, 'total_coefficient': 0};
    }

    double weightedSum = 0;
    int totalCoefficient = 0;

    for (final grade in grades) {
      final normalized = grade.normalizedScore;
      weightedSum += normalized * grade.coefficient;
      totalCoefficient += grade.coefficient;
    }

    final average = totalCoefficient > 0 ? weightedSum / totalCoefficient : 0;

    return {
      'average': double.parse(average.toStringAsFixed(2)),
      'count': grades.length,
      'total_coefficient': totalCoefficient,
      'grades': grades.map((g) => {
        'subject': g.subjectId,
        'type': g.type,
        'score': g.score,
        'max': g.maxScore,
        'percentage': g.percentage.toStringAsFixed(1),
        'normalized': g.normalizedScore.toStringAsFixed(2),
        'coefficient': g.coefficient,
      }).toList(),
    };
  }

  // ============================================================
  // MOYENNES — Par classe / matière
  // ============================================================
  Future<Map<String, dynamic>> getClassAverage({
    required String classId,
    required String subjectId,
    required DateTime date,
    String? schoolId,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];

    var query = _supabase
        .from('grades')
        .select()  // ✅ Pas de colonnes spécifiques
        .eq('class_id', classId)
        .eq('subject_id', subjectId)
        .eq('date', dateStr);

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }

    final response = await query;
    final records = response as List;

    if (records.isEmpty) {
      return {'class_average': 0.0, 'count': 0, 'min': 0, 'max': 0};
    }

    final percentages = records.map((r) {
      final score = (r['score'] as num).toDouble();
      final max = (r['max_score'] as num).toDouble();
      return max > 0 ? (score / max) * 100 : 0;
    }).toList();

    final avg = percentages.reduce((a, b) => a + b) / percentages.length;

    return {
      'class_average': double.parse(avg.toStringAsFixed(2)),
      'count': records.length,
      'min': double.parse(percentages.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)),
      'max': double.parse(percentages.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)),
    };
  }
}