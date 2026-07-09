// lib/presentation/pages/principal/class_detail/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '/../../../config/theme.dart';

Widget buildError(String m) {
  return Center(
      child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 16),
      Text(m,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red)),
    ]),
  ));
}

Widget buildEmpty(String m) {
  return Center(
      child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
      const SizedBox(height: 16),
      Text(m,
          style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500)),
    ]),
  ));
}

class StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const StatCard(
      {super.key,
      required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (color == Colors.blue)
      bg = const Color(0xFFDBEAFE);
    else if (color == Colors.green)
      bg = const Color(0xFFDCFCE7);
    else
      bg = const Color(0xFFF3E8FF);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DistributionBar extends StatelessWidget {
  final int b8, b810, a10, total;
  const DistributionBar(
      {super.key,
      required this.b8,
      required this.b810,
      required this.a10,
      required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0)
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('Aucune note')),
      );
    final r = b8 / total;
    final o = b810 / total;
    final g = a10 / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              if (r > 0)
                Expanded(
                    flex: (r * 100).round(),
                    child: Container(height: 16, color: Colors.red)),
              if (o > 0)
                Expanded(
                    flex: (o * 100).round(),
                    child: Container(height: 16, color: Colors.orange)),
              if (g > 0)
                Expanded(
                    flex: (g * 100).round(),
                    child: Container(height: 16, color: Colors.green)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 8, children: [
          LegendDot(color: Colors.red, label: 'Rouge (< 8): $b8'),
          LegendDot(color: Colors.orange, label: 'Orange (8-10): $b810'),
          LegendDot(color: Colors.green, label: 'Vert (≥ 10): $a10'),
        ]),
      ],
    );
  }
}

class AttSummary extends StatelessWidget {
  final Map<String, dynamic> att;
  const AttSummary({super.key, required this.att});

  @override
  Widget build(BuildContext context) {
    final p = att['present'] as int? ?? 0;
    final a = att['absent'] as int? ?? 0;
    final r = att['retard'] as int? ?? 0;
    final t = att['total'] as int? ?? 0;
    return Row(children: [
      AttItem('Présents', p, Colors.green),
      const SizedBox(width: 8),
      AttItem('Absents', a, Colors.red),
      const SizedBox(width: 8),
      AttItem('Retards', r, Colors.orange),
      const SizedBox(width: 8),
      AttItem('Total', t, Colors.grey),
    ]);
  }
}

class AttItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const AttItem(this.label, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (color == Colors.green)
      bg = const Color(0xFFDCFCE7);
    else if (color == Colors.red)
      bg = const Color(0xFFFEE2E2);
    else if (color == Colors.orange)
      bg = const Color(0xFFFEF3C7);
    else
      bg = const Color(0xFFF3F4F6);

    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(children: [
            Text(value.toString(),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}
