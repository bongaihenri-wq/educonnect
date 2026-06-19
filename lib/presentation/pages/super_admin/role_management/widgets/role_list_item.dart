// lib/presentation/pages/super_admin/role_management/widgets/role_list_item.dart
import 'package:flutter/material.dart';
import '/../../data/models/role_model.dart';

class RoleListItem extends StatelessWidget {
  final RoleModel role;
  final VoidCallback onToggle;
  final VoidCallback? onAssign;
  final VoidCallback? onCreateUser;

  const RoleListItem({
    super.key,
    required this.role,
    required this.onToggle,
    this.onAssign,
    this.onCreateUser,
  });

  @override
  Widget build(BuildContext context) {
    final bool isImportManaged = role.isImportManaged;
    final bool isAssistant = role.code == 'assistant';
    final bool isAdmin = role.code == 'admin';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header : Avatar + Nom + Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _getRoleColor(role.code).withOpacity(0.1),
                  child: Icon(
                    _getRoleIcon(role.code),
                    color: _getRoleColor(role.code),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3142),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // Badge code
                          _buildBadge(
                            text: role.code.toUpperCase(),
                            bgColor: Colors.grey[200]!,
                            textColor: Colors.grey[700]!,
                          ),
                          // Badge pays
                          if (role.countryCode != null)
                            _buildBadge(
                              text: _getCountryName(role.countryCode!),
                              bgColor: Colors.orange.withOpacity(0.1),
                              textColor: Colors.orange,
                              borderColor: Colors.orange.withOpacity(0.3),
                            ),
                          // Badge statut
                          _buildBadge(
                            text: role.isActive ? 'ACTIF' : 'INACTIF',
                            bgColor: role.isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            textColor: role.isActive ? Colors.green : Colors.red,
                            borderColor: role.isActive
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                          ),
                          // Badge SAV/Commercial
                          if (isAssistant)
                            _buildBadge(
                              text: 'SAV / COMMERCIAL',
                              bgColor: const Color(0xFF6C63FF).withOpacity(0.1),
                              textColor: const Color(0xFF6C63FF),
                              borderColor: const Color(0xFF6C63FF).withOpacity(0.3),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Info ligne — 🔒 Wrap au lieu de Row pour éviter overflow
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.format_list_numbered, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      'Niveau hiérarchique : ${role.level}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (isAdmin)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school, size: 14, color: Colors.red[300]),
                      const SizedBox(width: 4),
                      Text(
                        '1 école obligatoire',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[400],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),
            // Import managed warning
            if (isImportManaged) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rôle géré automatiquement par l\'import de données',
                        style: TextStyle(color: Colors.orange[800], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Actions
            if (!isImportManaged) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildActionButton(
                    icon: role.isActive ? Icons.block : Icons.check_circle,
                    label: role.isActive ? 'Désactiver' : 'Activer',
                    color: role.isActive ? Colors.red : Colors.green,
                    onTap: onToggle,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.person_add,
                    label: 'Attribuer',
                    color: const Color(0xFF6C63FF),
                    onTap: role.isActive ? onAssign : null,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.person_add_alt_1,
                    label: 'Créer',
                    color: Colors.teal,
                    onTap: role.isActive ? onCreateUser : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String text,
    required Color bgColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final bool isDisabled = onTap == null;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey[100] : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDisabled ? Colors.grey[300]! : color.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isDisabled ? Colors.grey[400] : color, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDisabled ? Colors.grey[400] : color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String code) {
    switch (code) {
      case 'admin':
        return Colors.red;
      case 'principal':
        return Colors.purple;
      case 'assistant':
        return const Color(0xFF6C63FF);
      case 'teacher':
        return Colors.blue;
      case 'parent':
        return Colors.teal;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String code) {
    switch (code) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'principal':
        return Icons.school;
      case 'assistant':
        return Icons.support_agent;
      case 'teacher':
        return Icons.person;
      case 'parent':
        return Icons.family_restroom;
      case 'student':
        return Icons.child_care;
      default:
        return Icons.person_outline;
    }
  }

  String _getCountryName(String code) {
    switch (code) {
      case '+225':
        return '🇨🇮 CI';
      case '+237':
        return '🇨🇲 CM';
      case '+221':
        return '🇸🇳 SN';
      case '+233':
        return '🇬🇭 GH';
      case '+226':
        return '🇧🇫 BF';
      case '+241':
        return '🇬🇦 GA';
      default:
        return code;
    }
  }
}