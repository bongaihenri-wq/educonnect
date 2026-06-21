// lib/presentation/pages/admin/widgets/schedule/current_course_card.dart
import 'package:flutter/material.dart';
import '/../config/theme.dart';
import 'call_status_badge.dart';
import 'schedule_utils.dart';

class CurrentCourseCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isCalled;

  const CurrentCourseCard({
    super.key,
    required this.entry,
    required this.isCalled,
  });

  @override
  Widget build(BuildContext context) {
    final className = entry['classes']?['name'] ?? 'Classe inconnue';
    final classLevel = entry['classes']?['level'] ?? '';
    final subjectName = entry['subjects']?['name'] ?? 'Sans matière';
    final teacherName = '${entry['app_users']?['first_name'] ?? ''} ${entry['app_users']?['last_name'] ?? ''}'.trim();
    final room = entry['room'] ?? 'Non assignée';
    final startTime = formatTime(entry['start_time']);
    final endTime = formatTime(entry['end_time']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.violet, AppTheme.violet.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'En ce moment',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              CallStatusBadge(isCalled: isCalled, lightMode: true),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subjectName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$className ($classLevel)',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              buildInfoItem(Icons.access_time, '$startTime - $endTime', Colors.white),
              buildInfoItem(Icons.person, teacherName.isNotEmpty ? teacherName : 'Non assigné', Colors.white),
              buildInfoItem(Icons.room, room, Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}