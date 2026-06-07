// lib/presentation/pages/admin/widgets/grade_class_card.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class GradeClassCard extends StatelessWidget {
  final String className;
  final double averageGrade;
  final int totalStudents;
  final int studentsBelow8;
  final double? previousAverage; // Pour calculer la tendance
  final VoidCallback onTap;

  const GradeClassCard({
    super.key,
    required this.className,
    required this.averageGrade,
    required this.totalStudents,
    required this.studentsBelow8,
    this.previousAverage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trend = previousAverage != null ? averageGrade - previousAverage! : 0.0;
    final trendColor = trend > 0 ? Colors.green : (trend < 0 ? Colors.red : Colors.grey);
    final trendIcon = trend > 0 ? Icons.trending_up : (trend < 0 ? Icons.trending_down : Icons.trending_flat);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        height: 170,
        padding: const EdgeInsets.all(12),
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
            // Nom classe
            Text(
              className,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.nightBlue,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Moyenne
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  averageGrade.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getGradeColor(averageGrade),
                  ),
                ),
                const Text(
                  '/20',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Tendance
            if (trend != 0)
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: trendColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 4),
            
            // Stats
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '$totalStudents élèves',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            if (studentsBelow8 > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, size: 12, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Text(
                      '$studentsBelow8 à risque',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 14) return Colors.green;
    if (grade >= 10) return Colors.orange;
    return Colors.red;
  }
}