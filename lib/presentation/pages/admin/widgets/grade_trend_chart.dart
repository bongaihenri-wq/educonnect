// lib/presentation/pages/admin/widgets/grade_trend_chart.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class GradeTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;
  // Format: [{'month': 'Sept', 'average': 12.5}, {'month': 'Oct', 'average': 11.8}, ...]

  const GradeTrendChart({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return _buildEmptyState();
    }

    // Calculer min/max pour l'échelle
    final values = monthlyData.map((d) => (d['average'] as num).toDouble()).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final yMin = (minValue - range * 0.1).clamp(0, 20);
    final yMax = (maxValue + range * 0.1).clamp(0, 20);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tendance Année Scolaire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.nightBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.violet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${monthlyData.length} mois',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.violet,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Moyennes générales par mois',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          
          // Graphique scrollable horizontal
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyData.map((data) {
                  final month = data['month'] as String;
                  final average = (data['average'] as num).toDouble();
                  final heightPercent = range > 0 
                      ? (average - yMin) / (yMax - yMin) 
                      : 0.5;
                  final barHeight = 120 * heightPercent;

                  return Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Valeur
                        Text(
                          average.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getColor(average),
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Barre
                        Container(
                          width: 40,
                          height: barHeight.clamp(10, 120),
                          decoration: BoxDecoration(
                            color: _getColor(average),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Mois
                        Text(
                          month,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Ligne de référence 10/20
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 20,
                height: 2,
                color: Colors.red.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Seuil de réussite (10/20)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColor(double grade) {
    if (grade >= 14) return Colors.green;
    if (grade >= 10) return Colors.orange;
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
            Icon(Icons.show_chart, color: Colors.grey[300], size: 48),
            const SizedBox(height: 8),
            Text(
              'Aucune donnée de tendance',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}