// lib/presentation/widgets/report/report_student_evolution_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '/../data/repositories/report_repository.dart';

class ReportStudentEvolutionChart extends StatelessWidget {
  final GradeStats stats;

  const ReportStudentEvolutionChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.grades.length < 2) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Pas assez de données pour le graphique\n(${stats.grades.length} note(s))',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final spots = _createSpots();
    final minY = (stats.minGrade ?? 0) - 2;
    final maxY = (stats.maxGrade ?? 20) + 2;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Évolution des notes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${stats.grades.length} notes sur la période',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // ─── GRAPHIQUE ───────────────────────────────────
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY.clamp(0, 18).toDouble(),
                  maxY: maxY.clamp(2, 20).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < stats.grades.length) {
                            final date = stats.grades[index].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: Colors.indigo,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          final grade = stats.grades[index];
                          final color = _getGradeColor(grade.value);
                          return FlDotCirclePainter(
                            radius: 5,
                            color: color,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.indigo.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.indigo.shade800,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final grade = stats.grades[index];
                          return LineTooltipItem(
                            '${grade.value.toStringAsFixed(1)}/20\n${grade.type}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      // Ligne de moyenne
                      HorizontalLine(
                        y: stats.average,
                        color: Colors.orange.withOpacity(0.5),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (_) => 'Moy: ${stats.average.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Ligne 10/20
                      HorizontalLine(
                        y: 10,
                        color: Colors.red.withOpacity(0.3),
                        strokeWidth: 1,
                        dashArray: [3, 3],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── LÉGENDE ─────────────────────────────────────
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(Colors.green, '≥ 15'),
                const SizedBox(width: 16),
                _legendItem(Colors.orange, '10-14'),
                const SizedBox(width: 16),
                _legendItem(Colors.red, '< 10'),
                const SizedBox(width: 16),
                _legendItem(Colors.orange.withOpacity(0.5), 'Moyenne', isLine: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _createSpots() {
    return stats.grades.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  Color _getGradeColor(double value) {
    if (value >= 15) return Colors.green;
    if (value >= 10) return Colors.orange;
    return Colors.red;
  }

  Widget _legendItem(Color color, String label, {bool isLine = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isLine
          ? Container(width: 16, height: 2, color: color)
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
