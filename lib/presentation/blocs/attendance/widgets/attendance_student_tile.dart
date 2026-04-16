import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/../../data/models/student_model.dart';
import '../attendance_helpers.dart';

class AttendanceStudentTile extends StatelessWidget {
  final StudentModel student;
  final dynamic status; // Utilise ton Enum AttendanceStatus
  final VoidCallback onToggle;

  const AttendanceStudentTile({
    super.key,
    required this.student,
    required this.status,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = AttendanceUIHelper.getStatusColor(status);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(color),
              const SizedBox(width: 12),
              _buildStudentInfo(),
              _buildStatusBadge(color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: color.withOpacity(0.1),
        child: Text(student.initials, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Text('N° ${student.matricule}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(AttendanceUIHelper.getStatusIcon(status), color: color, size: 16),
          const SizedBox(width: 4),
          Text(status.label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
