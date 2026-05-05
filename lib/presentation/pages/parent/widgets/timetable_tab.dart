// lib/presentation/pages/parent/widgets/timetable_tab.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'common_widgets.dart';

class TimetableTab extends StatelessWidget {
  final List<Map<String, dynamic>> timetable;

  const TimetableTab({super.key, required this.timetable});

  @override
  Widget build(BuildContext context) {
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonWidgets.buildSectionTitle('Emploi du temps'),
          const SizedBox(height: 12),
          
          if (timetable.isEmpty)
            CommonWidgets.buildEmptyState('Aucun emploi du temps disponible')
          else
            ...days.asMap().entries.map((entry) {
              final dayIndex = entry.key + 1;
              final dayName = entry.value;
              final dayCourses = timetable.where((t) => t['day_of_week'] == dayIndex).toList();
              
              return _buildDayCard(dayName, dayCourses);
            }),
        ],
      ),
    );
  }

  Widget _buildDayCard(String dayName, List<Map<String, dynamic>> courses) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bisDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.nightBlue,
            ),
          ),
          const SizedBox(height: 8),
          if (courses.isEmpty)
            Text(
              'Aucun cours',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.nightBlueLight.withOpacity(0.5),
              ),
            )
          else
            ...courses.map((c) => _buildCourseItem(c)),
        ],
      ),
    );
  }

  Widget _buildCourseItem(Map<String, dynamic> course) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.violet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              course['start_time'] ?? '--:--',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.violet,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              course['subjects']?['name'] ?? 'Cours',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.nightBlue,
              ),
            ),
          ),
          Text(
            course['room'] ?? '',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.nightBlueLight.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
