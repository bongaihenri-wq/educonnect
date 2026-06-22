// lib/services/super_admin_trimester_service.dart
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperAdminTrimesterService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getTrimesters(String schoolId) async {
    final result = await _supabase
        .from('school_trimesters')
        .select('id, name, start_date, end_date, created_at')
        .eq('school_id', schoolId)
        .order('start_date');
    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> createTrimester({
    required String schoolId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _supabase.from('school_trimesters').insert({
      'school_id': schoolId,
      'name': name,
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'end_date': DateFormat('yyyy-MM-dd').format(endDate),
    });
  }

  Future<void> updateTrimester({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _supabase.from('school_trimesters').update({
      'name': name,
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'end_date': DateFormat('yyyy-MM-dd').format(endDate),
    }).eq('id', id);
  }

  Future<void> deleteTrimester(String id) async {
    await _supabase.from('school_trimesters').delete().eq('id', id);
  }
}