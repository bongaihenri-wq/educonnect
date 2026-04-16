import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class CourseListSection extends StatelessWidget {
  const CourseListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Prochains cours', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.nightBlue)),
          ),
          const CourseCard(subject: 'Mathématiques', className: '6ème A', time: '08:00 - 09:30', room: 'Salle 12', color: AppTheme.violet),
          const SizedBox(height: 12),
          const CourseCard(subject: 'Physique-Chimie', className: '5ème B', time: '10:00 - 11:30', room: 'Labo 3', color: AppTheme.teal),
          const SizedBox(height: 12),
          const CourseCard(subject: 'Mathématiques', className: '4ème C', time: '14:00 - 15:30', room: 'Salle 8', color: AppTheme.violetLight),
        ]),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final String subject, className, time, room;
  final Color color;

  const CourseCard({super.key, required this.subject, required this.className, required this.time, required this.room, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bisDark),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$time • $room', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(className, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }
}
