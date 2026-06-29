// lib/presentation/pages/admin/school_report/widgets/grade_badge.dart
import 'package:flutter/material.dart';

class GradeBadge extends StatelessWidget {
  final double noteSur20;

  const GradeBadge({super.key, required this.noteSur20});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (noteSur20 >= 14) {
      color = Colors.green;
    } else if (noteSur20 >= 10) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${noteSur20.toStringAsFixed(1)}/20',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}