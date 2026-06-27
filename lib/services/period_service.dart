import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class PeriodService {
  final _supabase = Supabase.instance.client;

  /// Récupère TOUTES les périodes (dynamiques + académiques)
  Future<List<Map<String, dynamic>>> getAllPeriods(String schoolId) async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final weekStart = now.subtract(Duration(days: now.weekday - 1)).toIso8601String().split('T')[0];
    final weekEnd = now.add(Duration(days: 7 - now.weekday)).toIso8601String().split('T')[0];
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
    final monthEnd = DateTime(now.year, now.month + 1, 0).toIso8601String().split('T')[0];

    // Périodes dynamiques (toujours présentes)
    final dynamicPeriods = [
      {
        'name': 'Aujourd\'hui',
        'start_date': today,
        'end_date': today,
        'level': 1,
        'is_dynamic': true,
      },
      {
        'name': 'Cette semaine',
        'start_date': weekStart,
        'end_date': weekEnd,
        'level': 2,
        'is_dynamic': true,
      },
      {
        'name': 'Ce mois',
        'start_date': monthStart,
        'end_date': monthEnd,
        'level': 3,
        'is_dynamic': true,
      },
    ];

    // Périodes académiques depuis la base
    final academicResult = await _supabase.rpc(
      'get_school_periods_for_admin',
      params: {'p_school_id': schoolId},
    );

    final academicPeriods = List<Map<String, dynamic>>.from(academicResult).map((p) => {
      ...p,
      'is_dynamic': false,
    }).toList();

    return [...dynamicPeriods, ...academicPeriods];
  }

  Future<Map<String, dynamic>?> getCurrentPeriod(String schoolId) async {
    final allPeriods = await getAllPeriods(schoolId);
    final now = DateTime.now().toIso8601String().split('T')[0];

    // Chercher la période académique qui contient aujourd'hui
    for (final period in allPeriods) {
      if (period['is_dynamic'] == true) continue;
      final start = period['start_date'] as String;
      final end = period['end_date'] as String;
      if (now.compareTo(start) >= 0 && now.compareTo(end) <= 0) {
        return period;
      }
    }

    // Fallback : dernier trimestre académique
    final academicPeriods = allPeriods.where((p) => p['is_dynamic'] != true).toList();
    if (academicPeriods.isNotEmpty) return academicPeriods.last;

    return null;
  }

  Future<List<Map<String, dynamic>>> getAcademicPeriods(String schoolId) async {
    final result = await _supabase.rpc(
      'get_school_periods_for_admin',
      params: {'p_school_id': schoolId},
    );
    return List<Map<String, dynamic>>.from(result);
  }

  Future<Map<String, dynamic>?> getCurrentTrimester(String schoolId) async {
    final now = DateTime.now().toIso8601String().split('T')[0];
    final result = await _supabase.rpc(
      'get_current_trimester',
      params: {'p_school_id': schoolId},
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }
}