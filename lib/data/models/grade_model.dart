// lib/data/models/grade_model.dart
import 'package:equatable/equatable.dart';

class GradeModel extends Equatable {
  final String id;
  final String studentId;
  final String classId;
  final String subjectId;
  final String scheduleId;
  final String teacherId;
  final String schoolId;
  final String type;        // Devoir, Contrôle, Examen
  final double score;
  final double maxScore;
  final int coefficient;
  final String? comment;
  final DateTime date;
  final DateTime createdAt;

  const GradeModel({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.subjectId,
    required this.scheduleId,
    required this.teacherId,
    required this.schoolId,
    required this.type,
    required this.score,
    required this.maxScore,
    this.coefficient = 1,
    this.comment,
    required this.date,
    required this.createdAt,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;
  double get normalizedScore => maxScore > 0 ? (score / maxScore) * 20 : 0; // Sur 20

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id'],
      studentId: json['student_id'],
      classId: json['class_id'] ?? '',
      subjectId: json['subject_id'],
      scheduleId: json['schedule_id'] ?? '',
      teacherId: json['teacher_id'],
      schoolId: json['school_id'] ?? '',
      type: json['type'],
      score: (json['score'] as num).toDouble(),
      maxScore: (json['max_score'] as num).toDouble(),
      coefficient: json['coefficient'] ?? 1,
      comment: json['comment'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'class_id': classId,
      'subject_id': subjectId,
      'schedule_id': scheduleId,
      'teacher_id': teacherId,
      'school_id': schoolId,
      'type': type,
      'score': score,
      'max_score': maxScore,
      'coefficient': coefficient,
      'comment': comment,
      'date': date.toIso8601String().split('T')[0],
    };
  }

  @override
  List<Object?> get props => [id, studentId, subjectId, type, score];
}
