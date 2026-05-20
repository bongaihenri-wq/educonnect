// lib/presentation/pages/super_admin/role_management/widgets/role_list_item.dart
import 'package:flutter/material.dart';
import '/../../data/models/role_model.dart';

class RoleListItem extends StatelessWidget {
  final RoleModel role;
  final VoidCallback onToggle;
  final VoidCallback? onAssign;
  final VoidCallback? onCreateUser;  // ⭐ NOUVEAU callback

  const RoleListItem({
    super.key,
    required this.role,
    required this.onToggle,
    this.onAssign,
    this.onCreateUser,  // ⭐ NOUVEAU
  });

  @override
  Widget build(BuildContext context) {
    final bool isImportManaged = role.isImportManaged;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(role.code).withOpacity(0.1),
                  child: Icon(_getRoleIcon(role.code), color: _getRoleColor(role.code)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Code: ${role.code} • Niveau: ${role.level}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (role.countryCode != null)
                        Text(
                          'Pays: ${_getCountryName(role.countryCode!)}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: role.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.isActive ? 'Actif' : 'Inactif',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            if (isImportManaged) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rôle géré automatiquement par l\'import de données',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
           if (!isImportManaged)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onToggle,
                    icon: Icon(
                      role.isActive ? Icons.block : Icons.check_circle, 
                      size: 18,
                    ),
                    label: Text(role.isActive ? 'Désactiver' : 'Activer'),
                    style: TextButton.styleFrom(
                      foregroundColor: role.isActive ? Colors.red : Colors.green,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: role.isActive ? onAssign : null,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Attribuer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B4EFF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: role.isActive ? onCreateUser : null,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Créer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String code) {
    switch (code) {
      case 'admin': return Colors.red;
      case 'principal': return Colors.purple;
      case 'assistant': return Colors.orange;
      case 'teacher': return Colors.blue;
      case 'parent': return Colors.teal;
      case 'student': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String code) {
    switch (code) {
      case 'admin': return Icons.admin_panel_settings;
      case 'principal': return Icons.school;
      case 'assistant': return Icons.assistant;
      case 'teacher': return Icons.person;
      case 'parent': return Icons.family_restroom;
      case 'student': return Icons.child_care;
      default: return Icons.person_outline;
    }
  }

  String _getCountryName(String code) {
    switch (code) {
      case '+225': return '🇨🇮 Côte d\'Ivoire';
      case '+237': return '🇨🇲 Cameroun';
      case '+221': return '🇸🇳 Sénégal';
      case '+233': return '🇬🇭 Ghana';
      case '+226': return '🇧🇫 Burkina Faso';
      case '+241': return '🇬🇦 Gabon';
      default: return code;
    }
  }
}