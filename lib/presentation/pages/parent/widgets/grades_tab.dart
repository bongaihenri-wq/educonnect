// lib/presentation/pages/parent/widgets/grades_tab.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'common_widgets.dart';

class GradesTab extends StatelessWidget {
  final List<Map<String, dynamic>> grades;
  final Map<String, dynamic> stats;

  const GradesTab({
    super.key,
    required this.grades,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonWidgets.buildSectionTitle('Relevé de notes'),
          const SizedBox(height: 12),
          
          // Moyenne générale
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Moyenne générale',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  stats['average'] != null && (stats['average'] as double) > 0
                      ? '${(stats['average'] as double).toStringAsFixed(1)}/20'
                      : '-/20',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // ─── TABLEAU DES NOTES ─────────────
          if (grades.isEmpty)
            CommonWidgets.buildEmptyState('Aucune note enregistrée')
          else
            _buildGradesTable(),
        ],
      ),
    );
  }

  Widget _buildGradesTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête tableau
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Matière', style: _headerStyle())),
                  Expanded(flex: 3, child: Text('Type', style: _headerStyle())),
                  Expanded(flex: 1, child: Text('Coef', style: _headerStyle(), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('Note', style: _headerStyle(), textAlign: TextAlign.center)),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Lignes de notes
            ...grades.map((g) => _buildGradeRow(g)),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeRow(Map<String, dynamic> grade) {
    final value = (grade['score'] as num).toDouble();
    final maxValue = (grade['max_score'] as num?)?.toDouble() ?? 20.0;
    final subject = grade['subjects']?['name'] ?? 'Matière';
    final type = grade['type'] ?? 'Note';
    final coef = (grade['coefficient'] as num?)?.toInt() ?? 1;
    final noteSur20 = maxValue > 0 ? (value / maxValue) * 20 : 0.0;

    Color color;
    if (noteSur20 >= 14) color = Colors.green;
    else if (noteSur20 >= 10) color = Colors.orange;
    else color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Matière
          Expanded(
            flex: 3,
            child: Text(
              subject,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.nightBlue,
              ),
            ),
          ),
          // Type
          Expanded(
            flex: 3,
            child: Text(
              type,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          // Coefficient
          Expanded(
            flex: 1,
            child: Text(
              '$coef',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.nightBlue,
              ),
            ),
          ),
          // Note /20
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${noteSur20.toStringAsFixed(1)}/20',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppTheme.violet,
    );
  }
}