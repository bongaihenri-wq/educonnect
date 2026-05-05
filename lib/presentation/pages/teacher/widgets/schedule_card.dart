import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../data/models/teacher_class_schedule_model.dart';
import '/presentation/blocs/attendance/attendance_bloc.dart';
import '/presentation/blocs/attendance/attendance_event.dart';
import '/../config/routes.dart';

class ScheduleCard extends StatelessWidget {
  final TeacherClassScheduleModel schedule;

  const ScheduleCard({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final isCurrent = schedule.isCurrentSlot;
    final isPast = _isPast(schedule);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrent ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent ? BorderSide(color: Colors.green.shade300, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _handleTap(context, isPast, isCurrent),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildTimeBadge(isCurrent, isPast),
              const SizedBox(width: 16),
              Expanded(child: _buildInfo()),
              if (!isPast || isCurrent) const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBadge(bool isCurrent, bool isPast) {
    return Container(
      width: 55, height: 55,
      decoration: BoxDecoration(
        color: isCurrent ? Colors.green.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(schedule.startTime.substring(0, 5),
            style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? Colors.green.shade800 : Colors.blue.shade800)),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(schedule.className, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(schedule.subjectName, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 4),
        Text('${schedule.startTime} - ${schedule.endTime}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _handleTap(BuildContext context, bool isPast, bool isCurrent) {
    final state = context.read<AttendanceBloc>().state;
    final classModel = state.classes.firstWhere((c) => c.id == schedule.classId);
    
    context.read<AttendanceBloc>().add(AttendanceClassSelected(classModel, schoolId: ''));
    Navigator.pushNamed(context, AppRoutes.teacherAttendance);
  }

  bool _isPast(TeacherClassScheduleModel s) {
    final now = DateTime.now();
    final end = s.endTime.split(':');
    return now.hour > int.parse(end[0]) || (now.hour == int.parse(end[0]) && now.minute > int.parse(end[1]));
  }
}
