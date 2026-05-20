// lib/presentation/pages/super_admin/role_management/widgets/role_stats_bar.dart
import 'package:flutter/material.dart';
import '/../../data/models/role_model.dart';

class RoleStatsBar extends StatelessWidget {
  final List<RoleModel> roles;

  const RoleStatsBar({super.key, required this.roles});

  @override
  Widget build(BuildContext context) {
    final total = roles.length;
    final active = roles.where((r) => r.isActive).length;
    final inactive = total - active;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatItem('$total', 'Total', Colors.blue),
          const SizedBox(width: 12),
          _buildStatItem('$active', 'Actifs', Colors.green),
          const SizedBox(width: 12),
          _buildStatItem('$inactive', 'Inactifs', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}