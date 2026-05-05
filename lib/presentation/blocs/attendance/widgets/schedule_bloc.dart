import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/data/models/schedule_model.dart';

class ScheduleProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<ScheduleModel> _allSchedules = [];
  bool _isLoading = false;

  List<ScheduleModel> get allSchedules => _allSchedules;
  bool get isLoading => _isLoading;

  // Filtrer uniquement les cours d'aujourd'hui pour l'enseignant
  List<ScheduleModel> get todaySchedules {
    final now = DateTime.now();
    // weekday de Dart : 1=Lundi, 7=Dimanche. 
    // Notre base : 1=Lundi, 0=Dimanche. On harmonise :
    final currentDay = now.weekday == 7 ? 0 : now.weekday;
    return _allSchedules.where((s) => s.dayOfWeek == currentDay).toList();
  }

  ScheduleModel? get currentCourse {
    try {
      // .firstWhere utilise maintenant ton getter "isCurrent" mis à jour
      return todaySchedules.firstWhere((s) => s.isCurrent);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadSchedulesForTeacher(String teacherId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Appel à la Vue SQL créée à l'étape 1
      final response = await _supabase
          .from('view_active_schedules')
          .select()
          .eq('teacher_id', teacherId);

      _allSchedules = (response as List)
          .map((data) => ScheduleModel.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint("Erreur chargement planning: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}