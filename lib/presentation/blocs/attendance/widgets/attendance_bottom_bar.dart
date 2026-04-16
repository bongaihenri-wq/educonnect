import 'package:flutter/material.dart';

class AttendanceBottomBar extends StatelessWidget {
  final int present;
  final int absent;
  final int late;
  final int total;
  final bool isSubmitting;
  final VoidCallback? onValidate;

  const AttendanceBottomBar({
    super.key,
    required this.present,
    required this.absent,
    required this.late,
    required this.total,
    this.isSubmitting = false,
    this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem('✓', present, Colors.green, 'Présents'),
                _StatItem('✗', absent, Colors.red, 'Absents'),
                _StatItem('⏰', late, Colors.orange, 'Retards'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onValidate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Valider l\'appel ($present/$total)', 
                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final int count;
  final Color color;
  final String label;
  const _StatItem(this.icon, this.count, this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$icon $count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
