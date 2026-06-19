// lib/presentation/pages/super_admin/role_management/widgets/role_stats_bar.dart
import 'package:flutter/material.dart';
import '/../../data/models/role_model.dart';

class RoleStatsBar extends StatelessWidget {
  final List<RoleModel> roles;
  final List<String> excludedRoleCodes;

  const RoleStatsBar({
    super.key,
    required this.roles,
    this.excludedRoleCodes = const [
      'parent',
      'student',
      'eleve',
      'enfant',
      'pupil',
    ],
  });

  @override
  Widget build(BuildContext context) {
    // 🔒 Filtrage déjà fait en amont, mais on double la sécurité ici
    final filteredRoles = roles.where((r) {
      final code = r.code.toLowerCase().trim();
      return !excludedRoleCodes.contains(code);
    }).toList();

    final total = filteredRoles.length;
    final active = filteredRoles.where((r) => r.isActive).length;
    final inactive = total - active;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF8F9FE),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiItem(
              '$total',
              'Total',
              Icons.people,
              const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiItem(
              '$active',
              'Actifs',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiItem(
              '$inactive',
              'Inactifs',
              Icons.block,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // 🔒 Anti-overflow : maxLines + ellipsis
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}