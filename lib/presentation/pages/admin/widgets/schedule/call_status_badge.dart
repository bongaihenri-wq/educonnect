// lib/presentation/pages/admin/widgets/schedule/call_status_badge.dart
import 'package:flutter/material.dart';

class CallStatusBadge extends StatelessWidget {
  final bool isCalled;
  final bool lightMode;

  const CallStatusBadge({
    super.key,
    required this.isCalled,
    required this.lightMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isCalled
            ? (lightMode ? Colors.green.withOpacity(0.2) : Colors.green.withOpacity(0.1))
            : (lightMode ? Colors.orange.withOpacity(0.2) : Colors.orange.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCalled
              ? (lightMode ? Colors.green.withOpacity(0.4) : Colors.green.withOpacity(0.3))
              : (lightMode ? Colors.orange.withOpacity(0.4) : Colors.orange.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCalled ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 14,
            color: isCalled ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              isCalled ? 'Appel effectué' : 'Appel non effectué',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isCalled ? Colors.green : Colors.orange,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}