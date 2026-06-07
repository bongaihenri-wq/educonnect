// lib/presentation/pages/admin/widgets/homeworks/homework_list_view.dart
import 'package:flutter/material.dart';
import '../homework_card.dart';  // ← Remonte d'un niveau (de homeworks/ vers widgets/)

class HomeworkListView extends StatelessWidget {
  final List<Map<String, dynamic>> homeworks;
  final Function(Map<String, dynamic>) onTap;
  final Function(Map<String, dynamic>) onToggleComplete;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;

  const HomeworkListView({
    super.key,
    required this.homeworks,
    required this.onTap,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: homeworks.length,
      itemBuilder: (context, index) => HomeworkCard(
        homework: homeworks[index],
        onTap: () => onTap(homeworks[index]),
        onToggleComplete: () => onToggleComplete(homeworks[index]),
        onEdit: () => onEdit(homeworks[index]),
        onDelete: () => onDelete(homeworks[index]),
      ),
    );
  }
}