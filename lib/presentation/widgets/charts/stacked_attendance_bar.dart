// lib/presentation/widgets/charts/stacked_attendance_bar.dart
import 'package:flutter/material.dart';

class StackedAttendanceBar extends StatelessWidget {
  final String label;
  final double presentPercent;
  final double absentPercent;
  final double latePercent;
  final bool isSmall;

  const StackedAttendanceBar({
    super.key,
    required this.label,
    required this.presentPercent,
    required this.absentPercent,
    required this.latePercent,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = presentPercent + absentPercent + latePercent;
    final normPresent = total > 0 ? (presentPercent / total * 100) : 0.0;
    final normAbsent = total > 0 ? (absentPercent / total * 100) : 0.0;
    final normLate = total > 0 ? (latePercent / total * 100) : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 6 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildLegend('P', normPresent, Colors.green),
              const SizedBox(width: 8),
              _buildLegend('A', normAbsent, Colors.red),
              const SizedBox(width: 8),
              _buildLegend('R', normLate, Colors.orange),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: isSmall ? 20 : 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey[200],
            ),
            child: Row(
              children: [
                if (normPresent > 0)
                  _buildSegment(normPresent, Colors.green[400]!,
                      '${normPresent.toStringAsFixed(0)}%'),
                if (normAbsent > 0)
                  _buildSegment(normAbsent, Colors.red[400]!,
                      '${normAbsent.toStringAsFixed(0)}%'),
                if (normLate > 0)
                  _buildSegment(normLate, Colors.orange[400]!,
                      '${normLate.toStringAsFixed(0)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSegment(double percent, Color color, String text) {
    return Flexible(
      flex: percent.toInt().clamp(1, 100),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: percent > 15
            ? Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}