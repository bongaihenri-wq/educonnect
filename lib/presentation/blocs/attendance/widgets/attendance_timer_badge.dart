import 'package:flutter/material.dart';

class AttendanceTimerBadge extends StatelessWidget {
  const AttendanceTimerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
          SizedBox(width: 4),
          Text('Session en cours', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
