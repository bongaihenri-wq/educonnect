// lib/presentation/pages/admin/school_report/widgets/status_badge.dart
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String? status;

  const StatusBadge({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'present':
        statusColor = Colors.green;
        statusLabel = 'Prés';
        break;
      case 'absent':
        statusColor = Colors.red;
        statusLabel = 'Abs';
        break;
      case 'late':
        statusColor = Colors.orange;
        statusLabel = 'Rtd';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusLabel,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}