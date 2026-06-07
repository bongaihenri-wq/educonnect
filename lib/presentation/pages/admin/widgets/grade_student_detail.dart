// lib/presentation/pages/admin/widgets/grade_student_detail.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import './../widgets/responsive_dialog.dart';

class GradeStudentDetail extends StatelessWidget {
  final String studentName;
  final String matricule;
  final String className;
  final double generalAverage;
  final List<Map<String, dynamic>> subjectGrades;

  const GradeStudentDetail({
    super.key,
    required this.studentName,
    required this.matricule,
    required this.className,
    required this.generalAverage,
    required this.subjectGrades,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialog(
      maxHeightPercent: 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header compact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.violet,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    studentName.isNotEmpty ? studentName[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$className • $matricule',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Contenu scrollable
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Moyenne générale
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getColor(generalAverage).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getColor(generalAverage).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Moyenne Générale',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            generalAverage.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _getColor(generalAverage),
                            ),
                          ),
                          Text(
                            '/20',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Titre
                    Row(
                      children: [
                        const Icon(Icons.bar_chart, color: AppTheme.violet, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Notes par Matière',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.nightBlue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ✅ GRAPHIQUE SCROLLABLE HORIZONTAL
                    SizedBox(
                      height: 160,
                      child: subjectGrades.isEmpty
                          ? _buildEmptyState()
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: subjectGrades.map((subject) {
                                  final name = subject['subject'] as String;
                                  final average = (subject['average'] as num).toDouble();
                                  final count = subject['count'] as int? ?? 0;
                                  final lastGrade = subject['last_grade'] as num?;

                                  final maxBarHeight = 100.0;
                                  final barHeight = (average / 20) * maxBarHeight;

                                  return Container(
                                    width: 50,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          average.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getColor(average),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        if (lastGrade != null)
                                          Text(
                                            'D:${lastGrade.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: 7,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        const SizedBox(height: 2),
                                        Container(
                                          width: 35,
                                          height: barHeight.clamp(12, maxBarHeight),
                                          decoration: BoxDecoration(
                                            color: _getColor(average),
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(4),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '$count',
                                          style: TextStyle(
                                            fontSize: 7,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),

                    const SizedBox(height: 8),

                    // ✅ LÉGENDE COMPACTE
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        _buildLegend('≥14', Colors.green),
                        _buildLegend('10-14', Colors.orange),
                        _buildLegend('<10', Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bouton fermer
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Fermer'),
              ),
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

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, color: Colors.grey[300], size: 40),
          const SizedBox(height: 8),
          Text(
            'Aucune note',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}