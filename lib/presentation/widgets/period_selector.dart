// lib/presentation/pages/admin/widgets/period_selector.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class PeriodSelector extends StatelessWidget {
  final List<Map<String, dynamic>> periods;
  final Map<String, dynamic>? selectedPeriod;
  final ValueChanged<Map<String, dynamic>?> onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.periods,
    this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) return const SizedBox.shrink();

    final selectedName = selectedPeriod?['name'] as String? ?? 'Sélectionner une période';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.violet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: AppTheme.violet,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Période',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    isExpanded: true,
                    value: selectedPeriod,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.violet,
                      size: 20,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.nightBlue,
                    ),
                    hint: Text(
                      'Sélectionner une période',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    items: periods.map((period) {
                      final name = period['name'] as String;
                      final isDynamic = period['is_dynamic'] == true;
                      final startDate = period['start_date'] as String?;
                      final endDate = period['end_date'] as String?;
                      
                      String subtitle = '';
                      if (startDate != null && endDate != null) {
                        final start = DateTime.parse(startDate);
                        final end = DateTime.parse(endDate);
                        subtitle = '${start.day}/${start.month} - ${end.day}/${end.month}';
                      }

                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: period,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDynamic ? Colors.blue : AppTheme.violet,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty)
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (period == selectedPeriod)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.violet,
                                size: 18,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: onPeriodChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}