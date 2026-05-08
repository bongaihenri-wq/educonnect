// lib/presentation/pages/parent/widgets/presence_table_widget.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class PresenceTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> attendance;

  const PresenceTableWidget({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    if (attendance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Aucune présence pour cette période',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('Date', style: _headerStyle())),
                  Expanded(flex: 3, child: Text('Cours', style: _headerStyle())),
                  Expanded(flex: 3, child: Text('Horaire', style: _headerStyle())),
                  Expanded(flex: 2, child: Text('Statut', style: _headerStyle(), textAlign: TextAlign.center)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...attendance.map((a) => _buildRow(a)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> attendance) {
    final date = DateTime.parse(attendance['date'] as String);
    final status = attendance['status'] as String;
    final schedule = attendance['schedules'] as Map<String, dynamic>?;
    final subject = schedule?['subjects']?['name'] ?? 'Cours';
    final startTime = _formatTime(schedule?['start_time']);
    final endTime = _formatTime(schedule?['end_time']);

    Color color;
    String label;

    switch (status) {
      case 'present':
        color = Colors.green;
        label = 'Prés';
        break;
      case 'absent':
        color = Colors.red;
        label = 'Abs';
        break;
      case 'late':
        color = Colors.orange;
        label = 'Rtd';
        break;
      default:
        color = Colors.grey;
        label = '?';
    }

    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dateStr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.nightBlue,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              subject,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.nightBlue,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '$startTime - $endTime',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppTheme.violet,
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    final parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeStr;
  }
}