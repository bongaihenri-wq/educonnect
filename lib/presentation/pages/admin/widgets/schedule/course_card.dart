// lib/presentation/pages/admin/widgets/schedule/course_card.dart
import 'package:flutter/material.dart';
import '/../config/theme.dart';
import 'call_status_badge.dart';
import 'schedule_utils.dart';

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isCalled;
  final bool isPast;

  const CourseCard({
    super.key,
    required this.entry,
    required this.isCalled,
    required this.isPast,
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

    return Opacity(
      opacity: isPast ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isPast ? 0 : 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isPast ? Colors.grey[200] : AppTheme.violet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          startTime,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isPast ? Colors.grey[500] : AppTheme.violet,
                          ),
                        ),
                        Text(
                          endTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: isPast ? Colors.grey[400] : AppTheme.violet.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isPast ? Colors.grey[500] : AppTheme.nightBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$className ($classLevel)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          teacherName.isNotEmpty ? teacherName : 'Non assigné',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  CallStatusBadge(isCalled: isCalled, lightMode: false),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.room, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    room,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}