// lib/presentation/pages/teacher/widgets/report/report_class_kpi_cards.dart
import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';
import '/../../../data/repositories/report_repository.dart';

class ReportClassKPICards extends StatelessWidget {
  final ClassAttendanceStats attendance;
  final ClassGradeStats grades;

  const ReportClassKPICards({
    super.key,
    required this.attendance,
    required this.grades,
  });

 // Dans report_class_kpi_cards.dart, remplacer le build :

  @override
  Widget build(BuildContext context) {
    // ✅ CORRIGÉ : Calculs pondérés par coefficient
    final devoirStats = _calcWeightedAverage('devoir');
    final examenStats = _calcWeightedAverage('examen');
    final interroStats = _calcWeightedAverage('interro');
    final participationStats = _calcWeightedAverage('participation');

    // Taux présences
    final totalRecords = attendance.totalAbsences + 
        (attendance.classPresenceRate > 0 
            ? (attendance.totalAbsences / (1 - attendance.classPresenceRate / 100) * attendance.classPresenceRate / 100).toInt() 
            : 0);
    final absentRate = totalRecords > 0 ? (attendance.totalAbsences / totalRecords * 100) : 0;
    final lateRate = (100 - attendance.classPresenceRate - absentRate).clamp(0, 100);

    return SizedBox(
      height: 190,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCard(
            width: 170,
            title: 'Présences',
            icon: Icons.check_circle_outline,
            color: AppTheme.mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatRow('Présence', '${attendance.classPresenceRate.toStringAsFixed(0)}%', AppTheme.mint),
                _buildStatRow('Absence', '${absentRate.toStringAsFixed(0)}%', AppTheme.coral),
                _buildStatRow('Retard', '${lateRate.toStringAsFixed(0)}%', AppTheme.sunshine),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildCard(
            width: 170,
            title: 'Moyennes',
            icon: Icons.calculate_outlined,
            color: AppTheme.violet,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ CORRIGÉ : Na si pas de notes, sinon moyenne pondérée /20
                _buildStatRow('Gén', _formatAvg(grades.classAverage), AppTheme.violet),
                _buildStatRow('Int', _formatAvg(interroStats), AppTheme.teal),
                _buildStatRow('Dev', _formatAvg(devoirStats), AppTheme.mint),
                _buildStatRow('Exam', _formatAvg(examenStats), AppTheme.sunshine),
                _buildStatRow('Part', _formatAvg(participationStats), AppTheme.coral),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildCard(
            width: 170,
            title: 'Distribution',
            icon: Icons.pie_chart_outline,
            color: AppTheme.sunshine,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ CORRIGÉ : Libellés exacts demandés
                _buildStatRow('>15', '${grades.above15Count}', AppTheme.mint),
                _buildStatRow('12-15', '${grades.between12And15Count}', AppTheme.teal),
                _buildStatRow('10-12', '${grades.between10And12Count}', AppTheme.sunshine),
                _buildStatRow('<10', '${grades.below10Count}', AppTheme.coral),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NOUVEAU : Calcul moyenne pondérée par coefficient pour un type
  double? _calcWeightedAverage(String type) {
    final typeGrades = grades.grades.where((g) => g.type.toLowerCase() == type).toList();
    if (typeGrades.isEmpty) return null;

    double weightedSum = 0;
    int totalCoef = 0;

    for (final g in typeGrades) {
      final normalized = g.outOf > 0 ? (g.value / g.outOf) * 20 : 0; // Normaliser /20
      weightedSum += normalized * g.coefficient;
      totalCoef += g.coefficient;
    }

    return totalCoef > 0 ? weightedSum / totalCoef : null;
  }

  // ✅ NOUVEAU : Formater — Na si null, sinon X.X/20
  String _formatAvg(double? avg) {
    if (avg == null) return 'Na';
    return '${avg.toStringAsFixed(1)}/20';
  }

  Widget _buildCard({
    required double width,
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.nightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}