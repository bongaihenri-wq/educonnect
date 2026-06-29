// lib/services/period_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class PeriodService {
  final _supabase = Supabase.instance.client;

  /// Vérifie si une période est dynamique (pas d'id UUID)
  bool _isDynamicPeriod(Map<String, dynamic> period) {
    final id = period['id'] as String?;
    return id == null || id.startsWith('dynamic_');
  }

  /// Récupère TOUTES les périodes (dynamiques + académiques)
  Future<List<Map<String, dynamic>>> getAllPeriods(String schoolId) async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final weekStart = now.subtract(Duration(days: now.weekday - 1)).toIso8601String().split('T')[0];
    final weekEnd = now.add(Duration(days: 7 - now.weekday)).toIso8601String().split('T')[0];
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
    final monthEnd = DateTime(now.year, now.month + 1, 0).toIso8601String().split('T')[0];

    // ✅ Périodes dynamiques — id local
    final dynamicPeriods = [
      {
        'id': 'dynamic_today',
        'name': 'Aujourd\'hui',
        'start_date': today,
        'end_date': today,
        'level': 1,
      },
      {
        'id': 'dynamic_week',
        'name': 'Cette semaine',
        'start_date': weekStart,
        'end_date': weekEnd,
        'level': 2,
      },
      {
        'id': 'dynamic_month',
        'name': 'Ce mois',
        'start_date': monthStart,
        'end_date': monthEnd,
        'level': 3,
      },
    ];

    // ✅ Périodes académiques depuis la base — avec vrai id UUID
    final academicResult = await _supabase
        .from('school_trimester_definitions')
        .select('id, name, start_date, end_date, level, is_active')
        .eq('school_id', schoolId)
        .order('level');

    final academicPeriods = List<Map<String, dynamic>>.from(academicResult);

    developer.log('📅 PeriodService - Académiques: ${academicPeriods.map((p) => {'id': p['id'], 'name': p['name']}).toList()}');

    return [...dynamicPeriods, ...academicPeriods];
  }

  Future<Map<String, dynamic>?> getCurrentPeriod(String schoolId) async {
    final allPeriods = await getAllPeriods(schoolId);
    final now = DateTime.now().toIso8601String().split('T')[0];

    // Chercher la période académique qui contient aujourd'hui
    for (final period in allPeriods) {
      if (_isDynamicPeriod(period)) continue; // ✅ Utilise _isDynamicPeriod
      final start = period['start_date'] as String;
      final end = period['end_date'] as String;
      if (now.compareTo(start) >= 0 && now.compareTo(end) <= 0) {
        return period;
      }
    }

    // Fallback : dernier trimestre académique
    final academicPeriods = allPeriods.where((p) => !_isDynamicPeriod(p)).toList(); // ✅
    if (academicPeriods.isNotEmpty) return academicPeriods.last;

    return null;
  }

  Future<List<Map<String, dynamic>>> getAcademicPeriods(String schoolId) async {
    final result = await _supabase
        .from('school_trimester_definitions')
        .select('id, name, start_date, end_date, level, is_active')
        .eq('school_id', schoolId)
        .order('level');
    return List<Map<String, dynamic>>.from(result);
  }

  Future<Map<String, dynamic>?> getCurrentTrimester(String schoolId) async {
    final now = DateTime.now().toIso8601String().split('T')[0];
    final result = await _supabase
        .from('school_trimester_definitions')
        .select('id, name, start_date, end_date, level, is_active')
        .eq('school_id', schoolId)
        .eq('is_active', true)
        .lte('start_date', now)
        .gte('end_date', now)
        .single();
    return result;
  }
}