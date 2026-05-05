// lib/data/repositories/schedule_repository.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_model.dart';

class ScheduleRepository {
  final SupabaseClient _supabase;

  // On utilise le constructeur avec injection pour plus de cohérence
  ScheduleRepository(this._supabase);

  /// Récupère l'emploi du temps complet d'une école (FILTRÉ PAR SCHOOL_ID)
  Future<List<ScheduleModel>> fetchSchoolSchedules(String schoolId) async {
    try {
      // Note : On utilise la vue 'view_active_schedules' si elle existe, 
      // sinon remplacez par 'schedules'
      final response = await _supabase
          .from('view_active_schedules') 
          .select()
          .eq('school_id', schoolId)
          .order('day_of_week', ascending: true)
          .order('start_time', ascending: true);

      return (response as List)
          .map((data) => ScheduleModel.fromMap(data))
          .toList();
    } catch (e) {
      // Si la vue n'existe pas encore, on peut fallback sur la table schedules
      debugPrint('Tentative sur la table schedules car la vue a échoué : $e');
      
      final fallbackResponse = await _supabase
          .from('schedules')
          .select('*, subjects(name), classes(name)')
          .eq('school_id', schoolId)
          .order('day_of_week', ascending: true);
          
      return (fallbackResponse as List)
          .map((data) => ScheduleModel.fromMap(data))
          .toList();
    }
  }
}