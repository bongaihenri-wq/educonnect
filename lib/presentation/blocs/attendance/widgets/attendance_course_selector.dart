import 'package:educonnect/presentation/blocs/attendance/attendance_bloc.dart';
import 'package:educonnect/presentation/blocs/attendance/attendance_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../attendance_helpers.dart';

class AttendanceCourseSelector extends StatelessWidget {
  final dynamic state; // Remplace par ton AttendanceState

  const AttendanceCourseSelector({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<dynamic>(
      value: state.currentCourse,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: state.availableCourses.map<DropdownMenuItem<dynamic>>((course) {
        return DropdownMenuItem(
          value: course,
          child: Row(
            children: [
              Container(
                width: 4, height: 30,
                decoration: BoxDecoration(
                  color: AttendanceUIHelper.getSubjectColor(course.name),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(course.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${course.startTime} - ${course.endTime}', 
                       style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (course) {
        context.read<AttendanceBloc>().add(AttendanceCourseChanged(course));
      },
    );
  }
}
