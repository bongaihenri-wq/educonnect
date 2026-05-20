// lib/presentation/pages/super_admin/subscriptions/widgets/parents_to_relaunch_list.dart
import 'package:flutter/material.dart';

class ParentsToRelaunchList extends StatelessWidget {
  final List<Map<String, dynamic>> parents;
  final Function(String parentId) onCall;
  final Function(String parentId) onSendSMS;
  final Function(String parentId) onViewDetails;

  const ParentsToRelaunchList({
    super.key,
    required this.parents,
    required this.onCall,
    required this.onSendSMS,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (parents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            const Text(
              'Aucun parent à relancer ! 🎉',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: parents.length,
      itemBuilder: (context, index) {
        final parent = parents[index];
        return _buildParentCard(context, parent);
      },
    );
  }

  Widget _buildParentCard(BuildContext context, Map<String, dynamic> parent) {
    final name = '${parent['first_name']} ${parent['last_name']}';
    final phone = parent['phone'] ?? '';
    final schoolCode = parent['school_id']?.toString().substring(0, 8) ?? '';
    final schoolName = parent['school_name'] ?? '';
    final country = parent['school_country'] ?? '';
    final daysInactive = parent['days_inactive'] ?? 0;
    final category = parent['relance_category'] ?? '';
    final activityStatus = parent['activity_status'] ?? '';
    final studentName = '${parent['student_first_name'] ?? ''} ${parent['student_last_name'] ?? ''}';
    final matricule = parent['student_matricule'] ?? '';

    Color statusColor;
    IconData statusIcon;

    switch (activityStatus) {
      case 'never_connected':
        statusColor = const Color(0xFFFF1744);
        statusIcon = Icons.person_off;
        break;
      case 'expired':
        statusColor = const Color(0xFFFF6D00);
        statusIcon = Icons.timer_off;
        break;
      case 'no_subscription':
        statusColor = const Color(0xFFFFB300);
        statusIcon = Icons.money_off;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header : Statut + Jours
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        category.replaceAll('🔴 ', '').replaceAll('🟡 ', '').replaceAll('⚪ ', ''),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13, // ✅ AUGMENTÉ de 12 à 13
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$daysInactive j',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // ✅ AUGMENTÉ de 13 à 14
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info parent
            Row(
              children: [
                CircleAvatar(
                  radius: 20, // ✅ AUGMENTÉ de 18 à 20
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: statusColor, size: 22), // ✅ AUGMENTÉ de 20 à 22
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17, // ✅ AUGMENTÉ de 16 à 17
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14, // ✅ AUGMENTÉ de 13 à 14
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // École
            Row(
              children: [
                Icon(Icons.school, size: 16, color: Colors.grey[500]), // ✅ AUGMENTÉ de 14 à 16
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    schoolCode,
                    style: const TextStyle(
                      color: Color(0xFF6B4EFF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    schoolName.length > 18 ? '${schoolName.substring(0, 18)}...' : schoolName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (country.isNotEmpty)
                  Text(
                    country,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Élève
            if (studentName.trim().isNotEmpty)
              Row(
                children: [
                  Icon(Icons.child_care, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Élève: $studentName',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (matricule.isNotEmpty)
                    Text(
                      '🎓 $matricule',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 14),

            // Boutons — TAILLE INTERMÉDIAIRE
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onCall(parent['parent_id']),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text(
                      'Appeler',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onSendSMS(parent['parent_id']),
                    icon: const Icon(Icons.sms, size: 16),
                    label: const Text(
                      'SMS',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B4EFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => onViewDetails(parent['parent_id']),
                    icon: const Icon(Icons.visibility, color: Color(0xFF6B4EFF), size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}