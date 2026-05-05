// lib/domain/entities/attendance.dart
// ❌ SUPPRIMÉ : import 'package:educonnect/data/models/attendance_model.dart';
// ✅ Utiliser AttendanceStatus directement depuis le model qui importe ce fichier

import 'package:educonnect/data/models/attendance_model.dart';

class Attendance {
  final String id;
  final String studentId;
  final String? scheduleId;    // ✅ RENOMMÉ : courseId → scheduleId (aligné avec table SQL)
  final String? classId;       // ✅ AJOUTÉ : pour isolation
  final String teacherId;
  final String schoolId;       // ✅ AJOUTÉ : obligatoire pour RLS
  final DateTime date;
  final AttendanceStatus status;
  final DateTime createdAt;

  Attendance({
    required this.id,
    required this.studentId,
    this.scheduleId,
    this.classId,
    required this.teacherId,
    required this.schoolId,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentId: json['student_id'],
      scheduleId: json['schedule_id'],    // ✅ RENOMMÉ
      classId: json['class_id'],          // ✅ AJOUTÉ
      teacherId: json['teacher_id'],
      schoolId: json['school_id'] ?? '',  // ✅ AJOUTÉ
      date: DateTime.parse(json['date']),
      status: _parseStatus(json['status']), // ✅ Helper local
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'schedule_id': scheduleId,    // ✅ RENOMMÉ
      'class_id': classId,          // ✅ AJOUTÉ
      'teacher_id': teacherId,
      'school_id': schoolId,        // ✅ AJOUTÉ
      'date': date.toIso8601String().split('T')[0],
      'status': status.value,
    };
  }

  // ✅ Helper local pour parser sans dépendance circulaire
  static AttendanceStatus _parseStatus(String value) {
    switch (value) {
      case 'present': return AttendanceStatus.present;
      case 'absent': return AttendanceStatus.absent;
      case 'late': return AttendanceStatus.late;
      default: return AttendanceStatus.present;
    }
  }
}