// lib/presentation/widgets/academic_period_selector.dart

import 'package:flutter/material.dart';
import '../../config/theme.dart';

class AcademicPeriodSelector extends StatelessWidget {
  final List<Map<String, dynamic>> periods;
  final Map<String, dynamic>? selectedPeriod;
  final ValueChanged<Map<String, dynamic>?> onPeriodSelected;
  final bool showQuickOption;
  final String? quickOptionLabel;
  final bool quickOptionSelected;

  const AcademicPeriodSelector({
    super.key,
    required this.periods,
    this.selectedPeriod,
    required this.onPeriodSelected,
    this.showQuickOption = false,
    this.quickOptionLabel,
    this.quickOptionSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.violet.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Période d\'analyse',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (showQuickOption && quickOptionLabel != null)
                ChoiceChip(
                  label: Text(quickOptionLabel!),
                  selected: quickOptionSelected,
                  onSelected: (selected) {
                    if (selected) onPeriodSelected(null);
                  },
                ),
              ...periods.map((period) {
                final isSelected = selectedPeriod != null &&
                    selectedPeriod!['name'] == period['name'];
                final name = period['name'] as String;

                return ChoiceChip(
                  label: Text(name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onPeriodSelected(period);
                  },
                  selectedColor: AppTheme.violet.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.violet : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}