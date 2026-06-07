// lib/presentation/pages/admin/widgets/class_card.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../widgets/charts/stacked_attendance_bar.dart';
import 'student_list.dart';

class ClassCard extends StatelessWidget {
  final Map<String, dynamic> classe;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(Map<String, dynamic> student) onViewStudent;
  final Function(Map<String, dynamic> student, String classId) onDeleteStudent;
  final Function(String classId) onAddStudent;

  const ClassCard({
    super.key,
    required this.classe,
    required this.isExpanded,
    required this.onToggle,
    required this.onViewStudent,
    required this.onDeleteStudent,
    required this.onAddStudent,
  });

  @override
  Widget build(BuildContext context) {
    final classId = classe['id'] as String;
    final className = classe['name']?.toString() ?? 'Classe inconnue';
    final stats = classe['stats'] as Map<String, dynamic>? ?? {};
    final students = (classe['students'] as List<dynamic>?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              className,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stats['total_students'] ?? 0} élèves • ${stats['boys'] ?? 0} ♂ • ${stats['girls'] ?? 0} ♀',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.violet.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${stats['presence_rate'] ?? 0}% présence',
                          style: TextStyle(
                            color: AppTheme.violet,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StackedAttendanceBar(
                    label: 'Assiduité classe',
                    presentPercent: (stats['present_rate_pct'] as num?)?.toDouble() ?? 0.0,
                    absentPercent: (stats['absent_rate_pct'] as num?)?.toDouble() ?? 0.0,
                    latePercent: (stats['late_rate_pct'] as num?)?.toDouble() ?? 0.0,
                    isSmall: true,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpanded ? 'Masquer les élèves' : 'Voir les élèves',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded)
            StudentList(
              students: students,
              classId: classId,
              onView: onViewStudent,
              onDelete: onDeleteStudent,
              onAdd: () => onAddStudent(classId),
            ),
        ],
      ),
    );
  }
}
