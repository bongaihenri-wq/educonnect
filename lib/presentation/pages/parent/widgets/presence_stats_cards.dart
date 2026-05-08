// lib/presentation/pages/parent/widgets/presence_stats_cards.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class PresenceStatsCards extends StatelessWidget {
  final List<Map<String, dynamic>> attendance;

  const PresenceStatsCards({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    final present = attendance.where((a) => a['status'] == 'present').length;
    final absent = attendance.where((a) => a['status'] == 'absent').length;
    final late = attendance.where((a) => a['status'] == 'late').length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildCard('Prés', '$present', AppTheme.mint, Icons.check_circle),
          const SizedBox(width: 12),
          _buildCard('Abs', '$absent', AppTheme.coral, Icons.cancel),
          const SizedBox(width: 12),
          _buildCard('Rtd', '$late', AppTheme.sunshine, Icons.access_time),
        ],
      ),
    );
  }

  Widget _buildCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}