// lib/presentation/widgets/report/report_subject_selector.dart
import 'package:flutter/material.dart';

class ReportSubjectSelector extends StatelessWidget {
  final List<String> subjects;
  final String? selectedSubject;
  final ValueChanged<String> onSubjectSelected;

  const ReportSubjectSelector({
    super.key,
    required this.subjects,
    required this.selectedSubject,
    required this.onSubjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (subjects.length <= 1) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.book, size: 20, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Matière',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subjects.map((subject) {
                final isSelected = subject == selectedSubject;
                return ChoiceChip(
                  label: Text(subject),
                  selected: isSelected,
                  onSelected: (_) => onSubjectSelected(subject),
                  selectedColor: Colors.indigo.shade100,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.indigo : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
