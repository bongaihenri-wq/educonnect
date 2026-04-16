import 'package:educonnect/presentation/blocs/attendance/attendance_event.dart';
import 'package:flutter/material.dart';


class StudentAttendanceTile extends StatelessWidget {
  final dynamic student;
  final AttendanceStatus? status;
  final Function(AttendanceStatus) onStatusChanged;

  const StudentAttendanceTile({
    super.key,
    required this.student,
    this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isNotMarked = status == null;
    Color statusColor = _getStatusColor();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.2),
        child: Text(student.initials, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
      ),
      title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B))),
      subtitle: Text(isNotMarked ? 'Non marqué' : status!.label,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBtn(Icons.check, const Color(0xFF14B8A6), status == AttendanceStatus.present),
          const SizedBox(width: 8),
          _buildBtn(Icons.close, const Color(0xFFFB7185), status == AttendanceStatus.absent),
          const SizedBox(width: 8),
          _buildBtn(Icons.schedule, const Color(0xFFF59E0B), status == AttendanceStatus.late),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case AttendanceStatus.present: return const Color(0xFF14B8A6);
      case AttendanceStatus.absent: return const Color(0xFFFB7185);
      case AttendanceStatus.late: return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  Widget _buildBtn(IconData icon, Color color, bool isSelected) {
    return InkWell(
      onTap: () => onStatusChanged(_getStatusFromIcon(icon)),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: isSelected ? Colors.white : color),
      ),
    );
  }

  AttendanceStatus _getStatusFromIcon(IconData icon) {
    if (icon == Icons.check) return AttendanceStatus.present;
    if (icon == Icons.close) return AttendanceStatus.absent;
    return AttendanceStatus.late;
  }
}
