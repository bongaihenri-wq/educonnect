// lib/presentation/pages/super_admin/subscriptions/widgets/detail_row.dart
import 'package:flutter/material.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isReference;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.isReference = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            overflow: isReference ? TextOverflow.ellipsis : TextOverflow.clip,
            maxLines: isReference ? 1 : null,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}