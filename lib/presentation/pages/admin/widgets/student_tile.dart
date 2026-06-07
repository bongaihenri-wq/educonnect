// lib/presentation/pages/admin/widgets/student_tile.dart
import 'package:flutter/material.dart';

class StudentTile extends StatelessWidget {
  final Map<String, dynamic> student;
  final String classId;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const StudentTile({
    super.key,
    required this.student,
    required this.classId,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = student['first_name'] ?? '';
    final lastName = student['last_name'] ?? '';
    final matricule = student['matricule'] ?? 'N/A';
    final gender = student['gender']?.toString().toLowerCase() ?? '';

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: _getGenderColor(gender, true),
        child: Icon(
          _getGenderIcon(gender),
          size: 16,
          color: _getGenderColor(gender, false),
        ),
      ),
      title: Text(
        '$firstName $lastName',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        'Matricule: $matricule',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility, size: 18, color: Colors.grey),
            onPressed: onView,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Color? _getGenderColor(String gender, bool isBackground) {
    final isFemale = gender == 'f' || gender == 'female' || gender == 'feminin';
    if (isBackground) {
      return isFemale ? Colors.pink[100] : Colors.blue[100];
    }
    return isFemale ? Colors.pink : Colors.blue;
  }

  IconData _getGenderIcon(String gender) {
    final isFemale = gender == 'f' || gender == 'female' || gender == 'feminin';
    return isFemale ? Icons.female : Icons.male;
  }
}