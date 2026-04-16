import 'package:flutter/material.dart';

class AttendanceQuickActions extends StatelessWidget {
  final VoidCallback onMarkAllPresent;
  final VoidCallback onMarkAllAbsent;
  final VoidCallback onInvert;

  const AttendanceQuickActions({
    super.key,
    required this.onMarkAllPresent,
    required this.onMarkAllAbsent,
    required this.onInvert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _ActionBtn(Icons.check_circle, 'Tous présents', Colors.green, onMarkAllPresent),
          const SizedBox(width: 8),
          _ActionBtn(Icons.cancel, 'Tous absents', Colors.red, onMarkAllAbsent),
          const SizedBox(width: 8),
          _ActionBtn(Icons.shuffle, 'Inverser', Colors.orange, onInvert),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
