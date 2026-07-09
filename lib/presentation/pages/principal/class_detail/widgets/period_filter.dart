// lib/presentation/pages/principal/class_detail/widgets/period_filter.dart
import 'package:flutter/material.dart';
import '/../../../config/theme.dart';

class PeriodFilter extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const PeriodFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        children: options.map((p) {
          final sel = selected == p;
          return ChoiceChip(
            label: Text(p),
            selected: sel,
            onSelected: (_) => onSelected(p),
            selectedColor: AppTheme.violet,
            labelStyle: TextStyle(
              color: sel ? Colors.white : const Color(0xFF374151),
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: const Color(0xFFE5E7EB),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          );
        }).toList(),
      ),
    );
  }
}
