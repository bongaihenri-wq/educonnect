// lib/presentation/pages/admin/widgets/schedule/schedule_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

TimeOfDay? parseTime(dynamic time) {
  if (time == null) return null;
  String str = time.toString();
  if (str.length >= 5) str = str.substring(0, 5);
  final parts = str.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

String formatTime(dynamic time) {
  if (time == null) return '--:--';
  String str = time.toString();
  if (str.length >= 5) return str.substring(0, 5);
  return str;
}

String formatFullDate(DateTime d) {
  const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  return '${days[d.weekday - 1]} ${DateFormat('dd/MM/yyyy').format(d)}';
}

String formatTimeOfDay(TimeOfDay t) {
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

bool isCurrentlyRunning(DateTime selected, dynamic startTime, dynamic endTime) {
  final target = TimeOfDay.fromDateTime(selected);
  final start = parseTime(startTime);
  final end = parseTime(endTime);
  if (start == null || end == null) return false;
  final targetMin = target.hour * 60 + target.minute;
  final startMin = start.hour * 60 + start.minute;
  final endMin = end.hour * 60 + end.minute;
  return targetMin >= startMin && targetMin <= endMin;
}

bool isPastCourse(DateTime selected, dynamic endTime) {
  final target = TimeOfDay.fromDateTime(selected);
  final end = parseTime(endTime);
  if (end == null) return false;
  final targetMin = target.hour * 60 + target.minute;
  final endMin = end.hour * 60 + end.minute;
  return endMin < targetMin;
}

bool isUpcomingCourse(DateTime selected, dynamic startTime, dynamic endTime) {
  final target = TimeOfDay.fromDateTime(selected);
  final start = parseTime(startTime);
  final end = parseTime(endTime);
  if (start == null || end == null) return false;
  final targetMin = target.hour * 60 + target.minute;
  final startMin = start.hour * 60 + start.minute;
  final endMin = end.hour * 60 + end.minute;
  return !(targetMin >= startMin && targetMin <= endMin) && endMin >= targetMin;
}

Widget buildInfoItem(IconData icon, String text, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color.withOpacity(0.9)),
      const SizedBox(width: 6),
      Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: color.withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}