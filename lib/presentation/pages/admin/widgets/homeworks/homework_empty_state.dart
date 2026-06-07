// lib/presentation/pages/admin/widgets/homeworks/homework_empty_state.dart
import 'package:flutter/material.dart';

class HomeworkEmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onResetFilters;

  const HomeworkEmptyState({
    super.key,
    required this.hasFilters,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun devoir trouvé',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onResetFilters,
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ],
      ),
    );
  }
}