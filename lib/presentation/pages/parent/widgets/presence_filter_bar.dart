// lib/presentation/pages/parent/widgets/presence_filter_bar.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class PresenceFilterBar extends StatelessWidget {
  final String selectedPeriod;
  final String selectedSubject;
  final DateTime? selectedDate;
  final List<String> availableSubjects;
  final Function(String) onPeriodChanged;
  final Function(String) onSubjectChanged;
  final Function(DateTime) onDateChanged;

  const PresenceFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.selectedSubject,
    required this.selectedDate,
    required this.availableSubjects,
    required this.onPeriodChanged,
    required this.onSubjectChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  value: selectedPeriod,
                  items: const ['Tout', 'Jour', 'Mois', 'Trimestre'],
                  onChanged: onPeriodChanged,
                  icon: Icons.date_range,
                ),
              ),
              const SizedBox(width: 12),
              if (selectedPeriod != 'Tout')
                Expanded(
                  flex: 2,
                  child: _buildDatePicker(context),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            value: selectedSubject,
            items: availableSubjects,
            onChanged: onSubjectChanged,
            icon: Icons.school,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.violet.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.violet),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppTheme.violet),
                  const SizedBox(width: 8),
                  Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.nightBlue,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final dateStr = selectedDate != null
        ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
        : 'Sélectionner';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime(2027),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppTheme.violet,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.violet.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: AppTheme.violet),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.nightBlue,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}