import 'package:flutter/material.dart';

class AttendanceBottomBar extends StatelessWidget {
  final int present, absent, late, remaining, total;
  final double percentage;
  final bool isSubmitting;
  final String buttonText;  // ✅ AJOUTÉ
  final VoidCallback? onValidate;

  const AttendanceBottomBar({
    super.key,
    required this.present, required this.absent, required this.late,
    required this.remaining, required this.total, required this.percentage,
    required this.isSubmitting, 
    required this.buttonText,  // ✅ AJOUTÉ
    this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
      ]),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('✓ Présent', present, const Color(0xFF14B8A6)),
                _buildStat('🔴 Absent', absent, const Color(0xFFFB7185)),
                _buildStat('🟠 Retard', late, const Color(0xFFF59E0B)),
                _buildStat('? Restant', remaining, Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED)),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onValidate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(buttonText),  // ✅ Utilise le paramètre
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label.split(' ').last, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10)),
      ],
    );
  }
}