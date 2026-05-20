// lib/presentation/pages/super_admin/subscriptions/widgets/subscription_data_table.dart
import 'package:flutter/material.dart';

class SubscriptionDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> subscriptions;
  final VoidCallback onRefresh;

  const SubscriptionDataTable({
    super.key,
    required this.subscriptions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Aucun abonnement',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subscriptions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _SubscriptionItem(sub: subscriptions[index]);
      },
    );
  }
}

class _SubscriptionItem extends StatelessWidget {
  final Map<String, dynamic> sub;

  const _SubscriptionItem({required this.sub});

  @override
  Widget build(BuildContext context) {
    final name = '${sub['first_name'] ?? ''} ${sub['last_name'] ?? ''}'.trim();
    final phone = sub['phone'] ?? '';
    final school = sub['school_name'] ?? '';
    final status = sub['activity_status'] ?? '';
    final days = sub['days_inactive']?.toString() ?? '';

    Color statusColor;
    String statusText;

    switch (status) {
      case 'active':
        statusColor = const Color(0xFF00C853);
        statusText = 'Actif';
        break;
      case 'trial':
        statusColor = const Color(0xFFFFB300);
        statusText = 'Trial';
        break;
      case 'expired':
        statusColor = const Color(0xFFFF1744);
        statusText = 'Expiré';
        break;
      case 'never_connected':
        statusColor = const Color(0xFFFF6D00);
        statusText = 'Jamais';
        break;
      default:
        statusColor = Colors.grey;
        statusText = '-';
    }

    return InkWell(
      onTap: () => _showDetail(context, sub),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: statusColor.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    phone.isNotEmpty ? phone : '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (school.isNotEmpty)
                    Text(
                      school,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (days.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${days}j',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> sub) {
    final parentName = '${sub['first_name'] ?? ''} ${sub['last_name'] ?? ''}';
    final phone = sub['phone'] ?? '';
    final email = sub['email'] ?? '';
    final schoolName = sub['school_name'] ?? '';
    final schoolCode = sub['school_id']?.toString().substring(0, 8) ?? '';
    final studentName = '${sub['student_first_name'] ?? ''} ${sub['student_last_name'] ?? ''}';
    final matricule = sub['student_matricule'] ?? '';
    final status = sub['activity_status'] ?? '';
    final daysInactive = sub['days_inactive']?.toString() ?? '';
    final planType = sub['plan_type'] ?? '';
    final expiresAt = sub['trial_ends_at'] ?? sub['current_period_end'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF6B4EFF).withOpacity(0.1),
                    child: const Icon(Icons.person, color: Color(0xFF6B4EFF), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parentName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailSection('École', [
                '🏫 $schoolName',
                '🆔 $schoolCode',
              ]),
              _buildDetailSection('Élève', [
                '👤 $studentName',
                '🎓 $matricule',
              ]),
              _buildDetailSection('Abonnement', [
                '📊 Statut: $status',
                '📅 Plan: $planType',
                '⏰ Expire: $expiresAt',
                '📉 Inactif depuis: $daysInactive jours',
              ]),
              if (email.isNotEmpty)
                _buildDetailSection('Contact', [
                  '📧 $email',
                ]),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.phone),
                      label: const Text('Appeler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.sms),
                      label: const Text('SMS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4EFF),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            item,
            style: const TextStyle(fontSize: 14),
          ),
        )),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}