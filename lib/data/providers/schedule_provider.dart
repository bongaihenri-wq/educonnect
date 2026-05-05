import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../repositories/schedule_repository.dart';

class ScheduleProvider extends ChangeNotifier {
  late final ScheduleRepository _repository;
  
  List<ScheduleModel> _allSchedules = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ScheduleModel> get allSchedules => _allSchedules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Récupère le planning complet (Admin) ou filtré (Teacher)
  Future<void> loadSchedules(String schoolId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allSchedules = await _repository.fetchSchoolSchedules(schoolId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Utilitaire pour l'enseignant : récupère son cours actuel
  ScheduleModel? getTeacherCurrentCourse(String teacherId) {
    try {
      return _allSchedules.firstWhere(
        (s) => s.isCurrent && s.id.contains(teacherId), // Logique simplifiée
      );
    } catch (_) {
      return null;
    }
  }
 // Retourne les cours d'une classe, triés par jour et par heure
  List<ScheduleModel> getSchedulesByClass(String classId) {
    return _allSchedules
        .where((s) => s.classId == classId)
        .toList()
      ..sort((a, b) {
        // Tri par jour d'abord
        int dayComp = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (dayComp != 0) return dayComp;
        // Puis par heure de début
        return a.startTimeStr.compareTo(b.startTimeStr);
      });
  }

}
