import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class StatCardsRow extends StatelessWidget {
  const StatCardsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _StatCard(icon: Icons.people, value: '28', label: 'Élèves', color: AppTheme.violet),
            const SizedBox(width: 12),
            _StatCard(icon: Icons.class_, value: '3', label: 'Classes', color: AppTheme.teal),
            const SizedBox(width: 12),
            _StatCard(icon: Icons.assignment, value: '5', label: 'Cours', color: AppTheme.sunshine),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bisDark),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.nightBlue)),
            Text(label, style: TextStyle(fontSize: 11, color: AppTheme.nightBlue.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}
