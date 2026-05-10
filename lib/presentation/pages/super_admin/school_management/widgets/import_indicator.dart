import 'package:flutter/material.dart';

class ImportIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isComplete;
  final String count;

  const ImportIndicator({
    super.key,
    required this.icon,
    required this.label,
    required this.isComplete,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isComplete ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isComplete ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(count, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Icon(
            isComplete ? Icons.check_circle : Icons.warning,
            color: isComplete ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
}