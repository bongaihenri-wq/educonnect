// lib/presentation/pages/teacher/widgets/course_list_section.dart
import 'package:flutter/material.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../data/models/course_model.dart';

class CourseListSection extends StatelessWidget {
  final List<CourseModel> courses;

  const CourseListSection({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    // Filtrer les cours du jour
    final todayCourses = _getTodayCourses(courses);
    final hasCourses = todayCourses.isNotEmpty;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Header avec bouton "Voir tout"
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mes Cours & Classes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.nightBlue,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.teacherScheduleFull), // ⭐ NOUVEAU
                  child: const Text('Voir tout'),
                ),
              ],
            ),
          ),

          // Cours du jour ou message "Pas de cours"
          if (!hasCourses)
            _buildNoCoursesCard()
          else
            ...todayCourses.map((course) => _buildTodayCourseCard(context, course)),
        ]),
      ),
    );
  }

  List<CourseModel> _getTodayCourses(List<CourseModel> allCourses) {
    final today = DateTime.now().weekday; // 1=Lundi, 7=Dimanche
    return allCourses.where((c) => c.dayOfWeek == today).toList();
  }

  Widget _buildNoCoursesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.beach_access, color: Colors.green.shade400, size: 40),
          const SizedBox(height: 12),
          Text(
            'Pas de cours aujourd\'hui !',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Profitez de votre journée',
            style: TextStyle(color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCourseCard(BuildContext context, CourseModel course) {
    final isCurrent = _isCurrentCourse(course);
    final isPast = _isPastCourse(course);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? Colors.green.shade300 : AppTheme.bisDark,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [BoxShadow(color: Colors.green.shade100, blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Heure
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.green.shade100
                    : isPast
                        ? Colors.grey.shade100
                        : AppTheme.violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course.startTime.substring(0, 5),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCurrent
                          ? Colors.green.shade800
                          : isPast
                              ? Colors.grey
                              : AppTheme.violet,
                    ),
                  ),
                  Text(
                    course.endTime.substring(0, 5),
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrent
                          ? Colors.green.shade600
                          : isPast
                              ? Colors.grey
                              : AppTheme.violet.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Info cours
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.meeting_room, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${course.className} • ${course.room ?? 'Salle non assignée'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (isCurrent)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'En cours',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bouton Faire l'appel (si cours en cours ou à venir)
            if (!isPast)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.teacherAttendance,
                    arguments: {
                      'classId': course.classId,
                      'className': course.className,
                      'subjectId': course.subjectId,
                      'subjectName': course.subject,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent ? Colors.green : AppTheme.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isCurrent ? 'Appel' : 'Voir',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isCurrentCourse(CourseModel course) {
    final now = DateTime.now();
    final start = _parseTime(course.startTime);
    final end = _parseTime(course.endTime);
    return now.isAfter(start) && now.isBefore(end);
  }

  bool _isPastCourse(CourseModel course) {
    final now = DateTime.now();
    final end = _parseTime(course.endTime);
    return now.isAfter(end);
  }

  DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
