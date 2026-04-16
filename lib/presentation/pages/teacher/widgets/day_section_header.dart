import 'package:flutter/material.dart';

class DaySectionHeader extends StatelessWidget {
  final String dayName;
  final bool isToday;
  final bool isFirst;

  const DaySectionHeader({
    super.key,
    required this.dayName,
    required this.isToday,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 12, 
        top: isFirst ? 0 : 16, // Moins d'espace si c'est le premier élément de la liste
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isToday)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            dayName.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.blue.shade800 : Colors.grey.shade700,
              letterSpacing: 1,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 8),
            Text(
              'AUJOURD\'HUI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
