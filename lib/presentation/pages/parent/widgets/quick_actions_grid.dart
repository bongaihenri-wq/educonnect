// lib/presentation/pages/parent/widgets/quick_actions_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../blocs/auth_bloc/auth_bloc.dart';
import '../child_detail_page.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16), // ✅ Réduit
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accès rapide',
              style: TextStyle(
                fontSize: 16, // ✅ Réduit
                fontWeight: FontWeight.bold,
                color: AppTheme.nightBlue,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2, // ✅ Plus large (était 1.8)
              children: [
                _buildQuickAccess(
                  context: context,
                  icon: Icons.calendar_today,
                  label: 'Emploi du temps',
                  color: AppTheme.violetLight,
                  onTap: () => _navigateTo(context, 2), // Index 2 = EDT
                ),
                _buildQuickAccess(
                  context: context,
                  icon: Icons.show_chart,
                  label: 'Notes',
                  color: AppTheme.violet,
                  onTap: () => _navigateTo(context, 1), // Index 1 = Notes
                ),
                _buildQuickAccess(
                  context: context,
                  icon: Icons.chat_bubble_outline,
                  label: 'Messages',
                  color: AppTheme.teal,
                  onTap: () => _navigateTo(context, 3), // Index 3 = Commentaires
                ),
                _buildQuickAccess(
                  context: context,
                  icon: Icons.receipt_long,
                  label: 'Bulletins',
                  color: AppTheme.sunshine,
                  onTap: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // ✅ Réduit
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.bisDark, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6), // ✅ Réduit
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18), // ✅ Réduit
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12, // ✅ Réduit
                      fontWeight: FontWeight.w600,
                      color: AppTheme.nightBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (onTap == null)
                    Text(
                      'Bientôt',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade400,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 12, // ✅ Réduit
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, int tabIndex) {
    final state = context.read<AuthBloc>().state;
    if (state is! ParentAuthenticated || state.studentId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildDetailPage(
          studentId: state.studentId,
          studentName: state.studentName,
          studentMatricule: state.studentMatricule,
          className: state.className,
          parentName: '${state.firstName} ${state.lastName}',
          schoolName: state.schoolName,
          initialTab: tabIndex,
        ),
      ),
    );
  }
}