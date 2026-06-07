// lib/presentation/pages/admin/widgets/student_list.dart
import 'package:flutter/material.dart';
import 'student_tile.dart';

class StudentList extends StatelessWidget {
  final List<dynamic> students;
  final String classId;
  final Function(Map<String, dynamic> student) onView;
  final Function(Map<String, dynamic> student, String classId) onDelete;
  final VoidCallback onAdd;

  const StudentList({
    super.key,
    required this.students,
    required this.classId,
    required this.onView,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          const Divider(height: 1),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Élèves (${students.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Aucun élève dans cette classe',
                style: TextStyle(color: Colors.grey[500]),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index] as Map<String, dynamic>;
                    return StudentTile(
                      student: student,
                      classId: classId,
                      onView: () => onView(student),
                      onDelete: () => onDelete(student, classId),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
