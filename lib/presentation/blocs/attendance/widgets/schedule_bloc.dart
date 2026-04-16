import 'package:flutter/material.dart';
import '/data/models/schedule_model.dart';

class ScheduleProvider extends ChangeNotifier {
  List<ScheduleModel> _todaySchedules = [];
  bool _isLoading = false;

  List<ScheduleModel> get todaySchedules => _todaySchedules;
  bool get isLoading => _isLoading;

  // Récupère le cours qui doit avoir lieu maintenant
  ScheduleModel? get currentCourse {
    try {
      return _todaySchedules.firstWhere((s) => s.isCurrent);
    } catch (_) {
      // Si aucun cours ne correspond à l'heure actuelle, 
      // on peut retourner le prochain cours de la journée
      return _todaySchedules.isNotEmpty ? _todaySchedules.first : null;
    }
  }

  // Simulation de chargement depuis une API
  Future<void> loadSchedules(String teacherId) async {
    _isLoading = true;
    notifyListeners();

    // ICI : Appel API réel plus tard
    await Future.delayed(const Duration(seconds: 1));
    
    _todaySchedules = [
      ScheduleModel(
        id: "m1",
        subjectName: "Mathématiques",
        className: "Terminale S1",
        classId: "ID_S1",
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now().add(const Duration(minutes: 30)),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }
}