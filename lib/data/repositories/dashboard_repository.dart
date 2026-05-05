// lib/data/repositories/dashboard_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_stats.dart';

class DashboardRepository {
  final SupabaseClient _supabase;
  DashboardRepository(this._supabase);

  Future<DashboardStats> getGlobalStats(String schoolId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // ⭐ REQUÊTES PARALLÈLES
      final futures = await Future.wait([
        _getCount('students', schoolId: schoolId),
        _getCount('users', schoolId: schoolId, role: 'teacher'),
        _getCount('users', schoolId: schoolId, role: 'parent'),
        _getCount('classes', schoolId: schoolId),
        _getTodayAbsences(schoolId, today),
        _getTodayAttendanceRate(schoolId, today),
      ]);

      return DashboardStats(
        schoolId: schoolId,
        totalStudents: futures[0] as int,
        totalTeachers: futures[1] as int,
        totalParents: futures[2] as int,
        totalClasses: futures[3] as int,
        todayAbsences: futures[4] as int,
        todayAttendanceRate: futures[5] as double,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stack) {
      print('💥 Erreur DashboardRepository: $e');
      print(stack);
      throw Exception('Erreur chargement statistiques');
    }
  }

  // ⭐ MÉTHODE GÉNÉRIQUE CORRIGÉE
  Future<int> _getCount(
    String table, {
    required String schoolId,
    String? role,
  }) async {
    var query = _supabase
        .from(table)
        .select()
        .eq('school_id', schoolId);

    if (role != null) {
      query = query.eq('role', role);
    }

    // ⭐ CORRECTION : Utiliser count() sans FetchOptions
    final response = await query.count();
    return response.count as int;
  }

  // ⭐ COMPTAGE DES ABSENCES CORRIGÉ
  Future<int> _getTodayAbsences(String schoolId, String today) async {
    final response = await _supabase
        .from('attendance')
        .select()
        .eq('date', today)
        .eq('status', 'absent')
        .eq('school_id', schoolId)
        .count();

    return response.count as int;
  }

  // ⭐ TAUX DE PRÉSENCE CORRIGÉ
  Future<double> _getTodayAttendanceRate(String schoolId, String today) async {
    final response = await _supabase
        .from('attendance')
        .select('status')
        .eq('date', today)
        .eq('school_id', schoolId);

    if (response.isEmpty) return 0.0;

    final total = response.length;
    final present = response.where((r) => r['status'] == 'present').length;

    return (present / total) * 100;
  }

  // ⭐ STATS PAR CLASSE
  Future<List<ClassStats>> getStatsByClass(String schoolId) async {
    final response = await _supabase.rpc(
      'get_class_stats',
      params: {'p_school_id': schoolId},
    );

    return (response as List)
        .map((json) => ClassStats.fromJson(json))
        .toList();
  }

  // ⭐ TENDANCE 7 JOURS
  Future<List<DailyAttendance>> getWeeklyTrend(String schoolId) async {
    final sevenDaysAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String()
        .split('T')[0];

    final response = await _supabase
        .from('attendance')
        .select('date, status')
        .eq('school_id', schoolId)
        .gte('date', sevenDaysAgo)
        .order('date');

    // Grouper par date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final record in response) {
      final date = record['date'] as String;
      grouped.putIfAbsent(date, () => []).add(record);
    }

    return grouped.entries.map((entry) {
      final total = entry.value.length;
      final present = entry.value.where((r) => r['status'] == 'present').length;
      return DailyAttendance(
        date: DateTime.parse(entry.key),
        totalStudents: total,
        presentCount: present,
        rate: (present / total) * 100,
      );
    }).toList();
  }
}
