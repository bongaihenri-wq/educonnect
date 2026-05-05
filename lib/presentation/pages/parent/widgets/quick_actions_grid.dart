import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accès rapide',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.nightBlue,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildQuickAccess(
                  icon: Icons.calendar_today,
                  label: 'Emploi du temps',
                  color: AppTheme.violetLight,
                ),
                _buildQuickAccess(
                  icon: Icons.show_chart,
                  label: 'Notes & moyennes',
                  color: AppTheme.violet,
                ),
                _buildQuickAccess(
                  icon: Icons.chat_bubble_outline,
                  label: 'Messages profs',
                  color: AppTheme.teal,
                ),
                _buildQuickAccess(
                  icon: Icons.receipt_long,
                  label: 'Bulletins',
                  color: AppTheme.sunshine,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bisDark, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.nightBlue,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }
}
