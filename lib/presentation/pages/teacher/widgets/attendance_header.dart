import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceHeader extends StatelessWidget {
  final DateTime selectedDate;
  final String? className;
  final int studentCount;
  final VoidCallback onDateTap;
  final VoidCallback onBackPressed;

  const AttendanceHeader({
    super.key,
    required this.selectedDate,
    this.className,
    required this.studentCount,
    required this.onDateTap,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onBackPressed,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              GestureDetector(
                onTap: onDateTap,
                child: _buildDateBadge(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Faire l\'appel',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            className != null ? '$className • $studentCount élèves' : 'Sélectionnez une classe',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd MMM yyyy', 'fr_FR').format(selectedDate),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
