// lib/presentation/pages/admin/widgets/schedule/date_time_selector.dart
import 'package:flutter/material.dart';
import '/../config/theme.dart';
import 'schedule_utils.dart';

class DateTimeSelector extends StatelessWidget {
  final DateTime selectedDateTime;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback onReset;
  final bool isRealtime;

  const DateTimeSelector({
    super.key,
    required this.selectedDateTime,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onReset,
    required this.isRealtime,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = formatTimeOfDay(TimeOfDay.fromDateTime(selectedDateTime));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bisDark),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onDateTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.violet.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppTheme.violet, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            formatFullDate(selectedDateTime),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.nightBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: AppTheme.violet),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onTimeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.violet.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, color: AppTheme.violet, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.nightBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: AppTheme.violet, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (!isRealtime)
                      _buildBadge(
                        icon: Icons.history,
                        text: 'Vue historique',
                        color: Colors.orange,
                      )
                    else
                      _buildBadge(
                        icon: Icons.radio_button_checked,
                        text: 'Temps réel',
                        color: Colors.green,
                      ),
                  ],
                ),
              ),
              if (!isRealtime)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text(
                    'Maintenant',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.violet,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
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