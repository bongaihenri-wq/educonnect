// lib/core/utils/schedule_utils.dart
import 'package:flutter/material.dart';

/// Utilitaires pour manipuler les emplois du temps (schedules)
/// Les heures sont stockées en PostgreSQL au format TIME: "HH:MM:SS"
class ScheduleUtils {
  ScheduleUtils._(); // Constructeur privé, classe statique uniquement

  // ============================================
  // CONVERSION TIME -> DateTime
  // ============================================

  /// Convertit une heure PostgreSQL TIME "08:10:00" en DateTime aujourd'hui
  static DateTime timeToDateTime(String timeStr, {DateTime? referenceDate}) {
    final parts = timeStr.split(':');
    if (parts.length < 2) throw FormatException('Format invalide: $timeStr');
    
    final base = referenceDate ?? DateTime.now();
    return DateTime(
      base.year, base.month, base.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts.length > 2 ? int.parse(parts[2]) : 0,
    );
  }

  /// Convertit une heure en TimeOfDay (pour les TimePicker Flutter)
  static TimeOfDay timeToTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Convertit TimeOfDay en string PostgreSQL "HH:MM:SS"
  static String timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  // ============================================
  // COMPARAISONS & VÉRIFICATIONS
  // ============================================

  /// Vérifie si un cours est en ce moment
  static bool isCurrentClass(String startTime, String endTime) {
    final now = DateTime.now();
    final start = timeToDateTime(startTime);
    final end = timeToDateTime(endTime);
    return now.isAfter(start) && now.isBefore(end);
  }

  /// Vérifie si un cours est dans le futur (pas encore commencé)
  static bool isUpcoming(String startTime) {
    final now = DateTime.now();
    final start = timeToDateTime(startTime);
    return start.isAfter(now);
  }

  /// Vérifie si un cours est terminé
  static bool isFinished(String endTime) {
    final now = DateTime.now();
    final end = timeToDateTime(endTime);
    return now.isAfter(end);
  }

  /// Calcule la durée d'un cours en minutes
  static int durationInMinutes(String startTime, String endTime) {
    final start = timeToDateTime(startTime);
    final end = timeToDateTime(endTime);
    return end.difference(start).inMinutes;
  }

  /// Calcule la durée d'un cours en format "1h30" ou "45min"
  static String formatDuration(String startTime, String endTime) {
    final minutes = durationInMinutes(startTime, endTime);
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h${m}' : '${h}h';
    }
    return '${minutes}min';
  }

  // ============================================
  // FORMATAGE AFFICHAGE
  // ============================================

  /// Format "08h10 - 09h05"
  static String formatTimeRange(String start, String end) {
    return '${_formatShort(start)} - ${_formatShort(end)}';
  }

  /// Format "08h10"
  static String formatShort(String timeStr) {
    return timeStr.substring(0, 5).replaceAll(':', 'h');
  }

  /// Format "08:10"
  static String formatClock(String timeStr) {
    return timeStr.substring(0, 5);
  }

  /// Format complet avec durée: "08h10 - 09h05 (55min)"
  static String formatWithDuration(String start, String end) {
    return '${formatTimeRange(start, end)} (${formatDuration(start, end)})';
  }

  /// Affiche le statut du cours (En cours, À venir, Terminé)
  static String getStatus(String startTime, String endTime) {
    if (isCurrentClass(startTime, endTime)) return 'En cours';
    if (isUpcoming(startTime)) return 'À venir';
    return 'Terminé';
  }

  /// Couleur associée au statut
  static Color getStatusColor(String startTime, String endTime) {
    if (isCurrentClass(startTime, endTime)) return Colors.green;
    if (isUpcoming(startTime)) return Colors.orange;
    return Colors.grey;
  }

  // ============================================
  // GESTION DES JOURS
  // ============================================

  /// Convertit le numéro du jour (1=lundi...7=dimanche) en nom
  static String dayNumberToName(int day, {bool short = false}) {
    final days = short
        ? ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
        : ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    // PostgreSQL: 0=dimanche, mais on reçoit souvent 1-7
    final index = day % 7;
    return days[index];
  }

  /// Nom du jour actuel
  static String todayName({bool short = false}) {
    return dayNumberToName(DateTime.now().weekday % 7, short: short);
  }

  /// Vérifie si un jour correspond à aujourd'hui
  static bool isToday(int dayOfWeek) {
    // PostgreSQL day_of_week: 0=dimanche, Flutter weekday: 1=lundi...7=dimanche
    final now = DateTime.now().weekday % 7; // 1->1, 7->0
    return dayOfWeek == now;
  }

  // Helper privé
  static String _formatShort(String timeStr) {
    return timeStr.substring(0, 5).replaceAll(':', 'h');
  }
}
