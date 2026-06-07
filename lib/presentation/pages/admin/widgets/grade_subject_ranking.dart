// lib/presentation/pages/admin/widgets/grade_subject_ranking.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class GradeSubjectRanking extends StatelessWidget {
  final List<Map<String, dynamic>> subjectAverages;
  // Format: [{'subject': 'Maths', 'average': 14.2, 'student_count': 25}, ...]
  final bool showBest; // true = meilleures, false = en difficulté

  const GradeSubjectRanking({
    super.key,
    required this.subjectAverages,
    this.showBest = true,
  });

  @override
  Widget build(BuildContext context) {
    if (subjectAverages.isEmpty) {
      return _buildEmptyState();
    }

    // Trier par moyenne
    final sorted = List<Map<String, dynamic>>.from(subjectAverages)
      ..sort((a, b) {
        final avgA = (a['average'] as num).toDouble();
        final avgB = (b['average'] as num).toDouble();
        return showBest ? avgB.compareTo(avgA) : avgA.compareTo(avgB);
      });

    // Prendre les 5 premières
    final displayList = sorted.take(5).toList();

    final title = showBest ? 'Meilleures Matières' : 'Matières en Difficulté';
    final icon = showBest ? Icons.emoji_events : Icons.warning_amber;
    final color = showBest ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.nightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Barres verticales scrollable horizontal si trop long
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: displayList.map((subject) {
                final name = subject['subject'] as String;
                final average = (subject['average'] as num).toDouble();
                final studentCount = subject['student_count'] as int? ?? 0;
                
                // Hauteur proportionnelle (max 150px)
                final maxBarHeight = 150.0;
                final barHeight = (average / 20) * maxBarHeight;

                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Moyenne
                      Text(
                        average.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getColor(average),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Barre verticale
                      Container(
                        width: 50,
                        height: barHeight.clamp(20, maxBarHeight),
                        decoration: BoxDecoration(
                          color: _getColor(average),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Nom matière
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      
                      // Nombre d'élèves
                      Text(
                        '$studentCount élèves',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(double average) {
    if (average >= 14) return Colors.green;
    if (average >= 10) return Colors.orange;
    return Colors.red;
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart, color: Colors.grey[300], size: 48),
            const SizedBox(height: 8),
            Text(
              'Aucune donnée de matière',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}