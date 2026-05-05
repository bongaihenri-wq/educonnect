// lib/data/models/report_period_model.dart
import 'package:equatable/equatable.dart';

/// Types de période supportés
enum PeriodType {
  semaine,
  mois,
  trimestre,
  semestre,
  annee, month;

  String get label {
    switch (this) {
      case PeriodType.semaine:
        return 'Semaine';
      case PeriodType.mois:
        return 'Mois';
      case PeriodType.trimestre:
        return 'Trimestre';
      case PeriodType.semestre:
        return 'Semestre';
      case PeriodType.annee:
        return 'Année';
      case PeriodType.month:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}

/// Modèle représentant une période scolaire
class ReportPeriodModel extends Equatable {
  final PeriodType type;
  final String value; // Ex: '2025-T2', '2025-S1', '2025-W15', '2025-04'
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final String? schoolYear; // '2025-2026'

  const ReportPeriodModel({
    required this.type,
    required this.value,
    required this.label,
    required this.startDate,
    required this.endDate,
    this.schoolYear,
  });

  /// Génère les périodes disponibles pour une année scolaire
  static List<ReportPeriodModel> generateForSchoolYear({
    required String schoolYear, // '2025-2026'
    required DateTime yearStart,
    required DateTime yearEnd,
    required List<Map<String, dynamic>> trimesters,
    required List<Map<String, dynamic>>? semesters,
  }) {
    final periods = <ReportPeriodModel>[];

    // Trimestres
    for (final t in trimesters) {
      periods.add(ReportPeriodModel(
        type: PeriodType.trimestre,
        value: '${schoolYear.split('-')[0]}-T${t['number']}',
        label: '${t['number']}ᵉ Trimestre ${schoolYear.split('-')[0]}',
        startDate: DateTime.parse(t['start_date']),
        endDate: DateTime.parse(t['end_date']),
        schoolYear: schoolYear,
      ));
    }

    // Semestres (si applicable)
    if (semesters != null) {
      for (final s in semesters) {
        periods.add(ReportPeriodModel(
          type: PeriodType.semestre,
          value: '${schoolYear.split('-')[0]}-S${s['number']}',
          label: '${s['number']}ᵉ Semestre ${schoolYear.split('-')[0]}',
          startDate: DateTime.parse(s['start_date']),
          endDate: DateTime.parse(s['end_date']),
          schoolYear: schoolYear,
        ));
      }
    }

    // Mois de l'année
    var currentMonth = DateTime(yearStart.year, yearStart.month);
    final lastMonth = DateTime(yearEnd.year, yearEnd.month);
    while (!currentMonth.isAfter(lastMonth)) {
      periods.add(ReportPeriodModel(
        type: PeriodType.mois,
        value: '${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}',
        label: _monthName(currentMonth.month, currentMonth.year),
        startDate: DateTime(currentMonth.year, currentMonth.month, 1),
        endDate: DateTime(currentMonth.year, currentMonth.month + 1, 0),
        schoolYear: schoolYear,
      ));
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    }

    return periods;
  }

  static String _monthName(int month, int year) {
    final names = ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
                   'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return '${names[month]} $year';
  }

  /// Période actuelle par défaut (trimestre en cours)
  static ReportPeriodModel getCurrentPeriod(List<ReportPeriodModel> periods) {
    final now = DateTime.now();
    return periods.firstWhere(
      (p) => now.isAfter(p.startDate) && now.isBefore(p.endDate.add(const Duration(days: 1))),
      orElse: () => periods.last,
    );
  }

  @override
  List<Object?> get props => [type, value, startDate, endDate];
}
