// lib/data/models/dashboard_stats.dart
import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final String schoolId;
  final int totalStudents;
  final int totalTeachers;
  final int totalParents;
  final int totalClasses;
  final int todayAbsences;
  final double todayAttendanceRate;
  final DateTime lastUpdated;

  const DashboardStats({
    required this.schoolId,
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalParents,
    required this.totalClasses,
    required this.todayAbsences,
    required this.todayAttendanceRate,
    required this.lastUpdated,
  });

  // ⭐ Helpers pour l'affichage
  String get attendanceRateFormatted => '${todayAttendanceRate.toStringAsFixed(1)}%';
  
  bool get hasAttendanceData => todayAttendanceRate > 0;

  @override
  List<Object?> get props => [
    schoolId,
    totalStudents,
    totalTeachers,
    totalParents,
    totalClasses,
    todayAbsences,
    todayAttendanceRate,
    lastUpdated,
  ];
}

class ClassStats {
  final String classId;
  final String className;
  final int studentCount;
  final double attendanceRate;

  ClassStats({
    required this.classId,
    required this.className,
    required this.studentCount,
    required this.attendanceRate,
  });

  factory ClassStats.fromJson(Map<String, dynamic> json) {
    return ClassStats(
      classId: json['class_id'],
      className: json['class_name'],
      studentCount: json['student_count'],
      attendanceRate: (json['attendance_rate'] ?? 0).toDouble(),
    );
  }
}

class DailyAttendance {
  final DateTime date;
  final int totalStudents;
  final int presentCount;
  final double rate;

  DailyAttendance({
    required this.date,
    required this.totalStudents,
    required this.presentCount,
    required this.rate,
  });

  String get dayName => [
    'Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'
  ][date.weekday % 7];
}