// lib/core/utils/date_time_extensions.dart

import 'package:educonnect/core/utils/schedule_utils.dart';
import 'package:flutter/material.dart';

/// Extensions sur String pour les heures PostgreSQL
extension TimeStringExtension on String {
  /// "08:10:00" -> DateTime aujourd'hui à 08:10
  DateTime get toDateTimeToday => ScheduleUtils.timeToDateTime(this);
  
  /// "08:10:00" -> "08h10"
  String get toShortTime => ScheduleUtils.formatShort(this);
  
  /// "08:10:00" -> TimeOfDay
  TimeOfDay get toTimeOfDay => ScheduleUtils.timeToTimeOfDay(this);
}

/// Extensions sur DateTime
extension DateTimeExtension on DateTime {
  /// Compare uniquement l'heure (ignore la date)
  bool isSameTime(String timeStr) {
    final other = ScheduleUtils.timeToDateTime(timeStr, referenceDate: this);
    return hour == other.hour && minute == other.minute;
  }
}