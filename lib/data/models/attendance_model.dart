import 'package:flutter/material.dart';

enum AttendanceStatus {
  present('Présent'),
  absent('Absent'),
  late('En retard');

  final String label;
  const AttendanceStatus(this.label);

  String get value => name;
  static AttendanceStatus fromString(String value) {
    switch (value) {
      case 'present': return AttendanceStatus.present;
      case 'absent': return AttendanceStatus.absent;
      case 'late': return AttendanceStatus.late;
      default: return AttendanceStatus.present;
    }
  }

  String get emoji {
    switch (this) {
      case AttendanceStatus.present: return '✓';
      case AttendanceStatus.absent: return '✗';
      case AttendanceStatus.late: return '⏰';
    }
  }

  String get colorHex {
    switch (this) {
      case AttendanceStatus.present: return '#14B8A6';
      case AttendanceStatus.absent: return '#FB7185';
      case AttendanceStatus.late: return '#F59E0B';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present: return const Color(0xFF14B8A6);
      case AttendanceStatus.absent: return const Color(0xFFFB7185);
      case AttendanceStatus.late: return const Color(0xFFF59E0B);
    }
  }
}

class AttendanceSubmission {
  final String studentId;
  final String classId;
  final String teacherId;
  final String schoolId;
  final AttendanceStatus status;
  final DateTime date;

  AttendanceSubmission({
    required this.studentId,
    required this.classId,
    required this.teacherId,
    required this.schoolId,
    required this.status,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'class_id': classId,
      'teacher_id': teacherId,
      'school_id': schoolId,
      'status': status.value,
      'date': date.toIso8601String().split('T')[0],
    };
  }
}
