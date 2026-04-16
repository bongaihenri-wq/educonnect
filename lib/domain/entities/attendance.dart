// lib/domain/entities/attendance.dart
import '../../presentation/blocs/attendance/attendance_event.dart';

class Attendance {
  final String id;
  final String studentId;
  final String? courseId;
  final String teacherId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime createdAt;

  Attendance({
    required this.id,
    required this.studentId,
    this.courseId,
    required this.teacherId,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentId: json['student_id'],
      courseId: json['course_id'],
      teacherId: json['teacher_id'],
      date: DateTime.parse(json['date']),
      status: AttendanceStatusExtension.fromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'course_id': courseId,
      'teacher_id': teacherId,
      'date': date.toIso8601String().split('T')[0],
      'status': status.value,
    };
  }
}
