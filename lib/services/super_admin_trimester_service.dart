// lib/services/super_admin_trimester_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperAdminTrimesterService {
  final _supabase = Supabase.instance.client;

  Future<bool> _isSuperAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    return role == 'super_admin';
  }

  Future<List<Map<String, dynamic>>> getTrimesters(String schoolId) async {
    final isSuperAdmin = await _isSuperAdmin();
    developer.log('getTrimesters - schoolId: $schoolId, isSuperAdmin: $isSuperAdmin');

    if (isSuperAdmin) {
      final result = await _supabase.rpc(
        'get_school_trimesters_super_admin',
        params: {'p_school_id': schoolId},
      );
      developer.log('RPC result: $result');
      return List<Map<String, dynamic>>.from(result);
    }

    final result = await _supabase
        .from('school_trimester_definitions')
        .select('id, name, start_date, end_date, academic_year, order_index, created_at')
        .eq('school_id', schoolId)
        .order('order_index');
    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> createTrimester({
    required String schoolId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    String academicYear = '2025-2026';
    try {
      final response = await _supabase
          .from('schools')
          .select('current_school_year')
          .eq('id', schoolId)
          .maybeSingle();
      if (response != null && response['current_school_year'] != null) {
        academicYear = response['current_school_year'] as String;
      }
    } catch (e) {
      developer.log('Erreur année académique: $e');
    }

    int nextOrderIndex = 1;
    try {
      final existing = await _supabase
          .from('school_trimester_definitions')
          .select('order_index')
          .eq('school_id', schoolId)
          .order('order_index', ascending: false)
          .limit(1);
      if (existing.isNotEmpty && existing[0] != null) {
        nextOrderIndex = (existing[0]['order_index'] as int? ?? 0) + 1;
      }
    } catch (e) {
      developer.log('Erreur order_index: $e');
    }

    final result = await _supabase.rpc('create_trimester_with_period', params: {
      'p_school_id': schoolId,
      'p_name': name,
      'p_start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'p_end_date': DateFormat('yyyy-MM-dd').format(endDate),
      'p_academic_year': academicYear,
      'p_order_index': nextOrderIndex,
    });

    bool success = false;
    String? errorMessage;

    if (result == null) {
      success = true;
    } else if (result is bool) {
      success = result;
    } else if (result is Map) {
      success = result['success'] == true;
      errorMessage = result['error']?.toString();
    } else if (result is String) {
      try {
        final decoded = jsonDecode(result);
        if (decoded is Map) {
          success = decoded['success'] == true;
          errorMessage = decoded['error']?.toString();
        }
      } catch (_) {
        success = true;
      }
    }

    if (!success) {
      throw Exception(errorMessage ?? 'Erreur création trimestre');
    }
  }

  Future<void> updateTrimester({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _supabase.rpc('update_trimester_with_period', params: {
      'p_trimester_id': id,
      'p_name': name,
      'p_start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'p_end_date': DateFormat('yyyy-MM-dd').format(endDate),
    });

    bool success = false;
    String? errorMessage;

    if (result == null) {
      success = true;
    } else if (result is bool) {
      success = result;
    } else if (result is Map) {
      success = result['success'] == true;
      errorMessage = result['error']?.toString();
    } else if (result is String) {
      try {
        final decoded = jsonDecode(result);
        if (decoded is Map) {
          success = decoded['success'] == true;
          errorMessage = decoded['error']?.toString();
        }
      } catch (_) {
        success = true;
      }
    }

    if (!success) {
      throw Exception(errorMessage ?? 'Erreur mise à jour trimestre');
    }
  }

  Future<void> deleteTrimester(String id) async {
    final result = await _supabase.rpc('delete_trimester_with_period', params: {
      'p_trimester_id': id,
    });

    bool success = false;
    String? errorMessage;

    if (result == null) {
      success = true;
    } else if (result is bool) {
      success = result;
    } else if (result is Map) {
      success = result['success'] == true;
      errorMessage = result['error']?.toString();
    } else if (result is String) {
      try {
        final decoded = jsonDecode(result);
        if (decoded is Map) {
          success = decoded['success'] == true;
          errorMessage = decoded['error']?.toString();
        }
      } catch (_) {
        success = true;
      }
    }

    if (!success) {
      throw Exception(errorMessage ?? 'Erreur suppression trimestre');
    }
  }
}