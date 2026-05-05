// lib/presentation/pages/teacher/widgets/report/report_class_student_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../config/theme.dart';
import '../../../../blocs/report/report_bloc.dart';
import '../../../../blocs/report/report_events.dart';
import '../../../../blocs/report/report_state.dart';

class ReportClassStudentSelector extends StatelessWidget {
  const ReportClassStudentSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        if (state.classes.isEmpty) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                Row(
                  children: [
                    Icon(Icons.school_outlined, size: 18, color: AppTheme.violet),
                    const SizedBox(width: 8),
                    Text('Sélection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildClassDropdown(context, state),
                if (state.selectedClassId != null) ...[
                  const SizedBox(height: 12),
                  _buildStudentDropdown(context, state),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassDropdown(BuildContext context, ReportState state) {
    Map<String, dynamic>? selectedClass;
    if (state.selectedClassId != null) {
      try {
        selectedClass = state.classes.firstWhere((c) => c['id'] == state.selectedClassId);
      } catch (e) {
        selectedClass = null;
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          isExpanded: true,
          value: selectedClass,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Choisir une classe', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ),
          icon: const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.arrow_drop_down, size: 20)),
          items: state.classes.map((classData) {
            final className = classData['name'] as String? ?? 'Sans nom';
            final classId = classData['id'] as String? ?? '';
            final levelName = classData['level_name'] as String? ?? '';
            
            return DropdownMenuItem<Map<String, dynamic>>(
              value: classData,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.violet, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(className, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                          if (levelName.isNotEmpty)
                            Text(levelName, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Text(classId.substring(0, 6).toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (selected) {
            if (selected != null) {
              final classId = selected['id'] as String;
              final className = selected['name'] as String;
              context.read<ReportBloc>().add(ReportClassSelected(classId, className));
            }
          },
        ),
      ),
    );
  }

Widget _buildStudentDropdown(BuildContext context, ReportState state) {
  // Debug
  print('🎨 STUDENTS in dropdown: ${state.students.length}');
  for (final s in state.students) {
    print('🎨   - ${s['full_name']} (id: ${s['id']})');
  }

  final items = <DropdownMenuItem<String?>>[
    const DropdownMenuItem(
      value: null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.groups, size: 18, color: Colors.grey),
            SizedBox(width: 10),
            Text('Toute la classe', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  ];

  for (final student in state.students) {
    final studentId = student['id'] as String;
    final fullName = student['full_name'] as String;
    
    items.add(DropdownMenuItem(
      value: studentId,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.person_outline, size: 18, color: AppTheme.violet.withOpacity(0.6)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fullName,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
      color: Colors.grey.shade50,
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        isExpanded: true,
        value: state.selectedStudentId,
        hint: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.groups, size: 18, color: Colors.grey),
              SizedBox(width: 10),
              Text('Voir toute la classe', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        icon: const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.arrow_drop_down, size: 20)),
        items: items,
        onChanged: (studentId) {
          print('🎯 Student selected: $studentId');
          
          String? studentName;
          if (studentId != null) {
            try {
              final student = state.students.firstWhere((s) => s['id'] == studentId);
              studentName = student['full_name'] as String?;
              print('🎯 Found student: $studentName');
            } catch (e) {
              print('🎯 Student not found');
              studentName = null;
            }
          }
          
          context.read<ReportBloc>().add(
            ReportStudentSelected(studentId: studentId, studentName: studentName),
          );
        },
      ),
    ),
  );
}
}
