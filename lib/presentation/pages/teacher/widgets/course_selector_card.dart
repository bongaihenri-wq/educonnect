import 'package:flutter/material.dart';
import '/../data/models/course_model.dart';

class CourseSelectorCard extends StatelessWidget {
  final List<CourseModel> courses;
  final CourseModel? currentCourse;
  final bool isAutoDetected;
  final Function(CourseModel?) onCourseChanged;

  const CourseSelectorCard({
    super.key,
    required this.courses,
    this.currentCourse,
    required this.isAutoDetected,
    required this.onCourseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          courses.isEmpty ? _buildEmptyState() : _buildDropdown(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.schedule_outlined, color: Color(0xFF7C3AED)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cours',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (isAutoDetected)
                const Text(
                  'Détection automatique',
                  style: TextStyle(fontSize: 12, color: Color(0xFF14B8A6)),
                ),
            ],
          ),
        ),
        if (isAutoDetected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, size: 14, color: Color(0xFF14B8A6)),
                Text(
                  ' Auto',
                  style: TextStyle(
                    color: Color(0xFF14B8A6),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<CourseModel?>(
      value: currentCourse,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      hint: const Text('Sélectionner un cours'),
      items: courses.map((course) {
        return DropdownMenuItem<CourseModel?>(
          value: course,
          child: Text('${course.name} (${course.displayTime})'),
        );
      }).toList(),
      onChanged: onCourseChanged,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Aucun cours prévu pour cette classe aujourd\'hui.',
        style: TextStyle(color: Color(0xFF92400E)),
      ),
    );
  }
}