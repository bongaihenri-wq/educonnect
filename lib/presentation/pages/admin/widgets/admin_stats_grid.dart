// lib/presentation/pages/admin/widgets/admin_stats_grid.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class AdminStatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final VoidCallback onRetry;

  const AdminStatsGrid({
    super.key,
    required this.stats,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (stats['loading'] == true) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (stats['error'] != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Erreur stats: ${stats['error']}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.red),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6, // PLUS PETIT (était 1.3)
        children: [
          _statCard('Classes', '${stats['classes']}', Icons.class_, Colors.blue),
          _statCard('Élèves', '${stats['students']}', Icons.school, Colors.green),
          _statCard('Enseignants', '${stats['teachers']}', Icons.person, Colors.orange),
          _statCard('Parents', '${stats['parents']}', Icons.family_restroom, Colors.purple),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12), // Réduit de 16 à 12
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Réduit de 16 à 12
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, // Réduit de 10 à 8
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22), // Réduit de 28 à 22
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16, // Réduit de 24 à 16
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11, // Réduit de 12 à 11
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}