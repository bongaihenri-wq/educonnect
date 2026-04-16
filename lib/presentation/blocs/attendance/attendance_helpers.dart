import 'package:flutter/material.dart';
import '../../../../data/models/attendance_model.dart'; // Ajuste selon ton projet

class AttendanceUIHelper {
  static Color getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return const Color(0xFF14B8A6);
      case AttendanceStatus.absent: return const Color(0xFFFB7185);
      case AttendanceStatus.late: return const Color(0xFFF59E0B);
    }
  }

  static IconData getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Icons.check;
      case AttendanceStatus.absent: return Icons.close;
      case AttendanceStatus.late: return Icons.schedule;
    }
  }

  static Color getSubjectColor(String subject) {
    final colors = {
      'mathématiques': Colors.blue, 'maths': Colors.blue,
      'français': Colors.red, 'anglais': Colors.purple,
    };
    return colors[subject.toLowerCase()] ?? Colors.indigo;
  }
}
