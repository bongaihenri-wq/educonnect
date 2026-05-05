// lib/presentation/pages/teacher/widgets/report/report_period_selector.dart
import 'package:flutter/material.dart';
import '/../../../config/theme.dart';
import '/../../../data/models/report_period_model.dart';

class ReportPeriodSelector extends StatelessWidget {
  final List<ReportPeriodModel> periods;
  final ReportPeriodModel? selectedPeriod;
  final Function(ReportPeriodModel) onPeriodSelected;

  const ReportPeriodSelector({
    super.key,
    required this.periods,
    required this.selectedPeriod,
    required this.onPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.violet),
                const SizedBox(width: 8),
                Text(
                  'Période',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ✅ DROPDOWN UNIQUE (plus de chips Trimestres/Semestres)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ReportPeriodModel>(
                  isExpanded: true,
                  value: selectedPeriod,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Choisir une période', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  ),
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.arrow_drop_down, size: 20),
                  ),
                  items: periods.map((period) {
                    return DropdownMenuItem<ReportPeriodModel>(
                      value: period,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: period == selectedPeriod ? AppTheme.violet : Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                period.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: period == selectedPeriod ? FontWeight.w600 : FontWeight.w400,
                                  color: AppTheme.nightBlue,
                                ),
                              ),
                            ),
                            Text(
                              '${period.startDate.day}/${period.startDate.month} - ${period.endDate.day}/${period.endDate.month}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (period) {
                    if (period != null) onPeriodSelected(period);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}