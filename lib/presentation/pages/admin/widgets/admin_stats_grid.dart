import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class AdminStatsGrid extends StatelessWidget {
  const AdminStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vue d\'ensemble',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.nightBlue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStat(Icons.people_alt, '452', 'Élèves', AppTheme.violet),
              const SizedBox(width: 12),
              _buildStat(Icons.school, '28', 'Classes', const Color(0xFF14B8A6)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStat(Icons.person_outline, '34', 'Profs', const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              _buildStat(Icons.family_restroom, '386', 'Parents', const Color(0xFFFB7185)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bisDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.nightBlue),
            ),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
