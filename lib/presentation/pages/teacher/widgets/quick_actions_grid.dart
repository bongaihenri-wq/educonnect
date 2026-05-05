// lib/presentation/pages/teacher/widgets/quick_actions_grid.dart
import 'package:flutter/material.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../teacher_reports_page.dart';

class QuickActionsGrid extends StatelessWidget {
  final String teacherId;
  final String schoolId;

  const QuickActionsGrid({
    super.key,
    required this.teacherId,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ UTILISER LES PARAMÈTRES REÇUS, pas context.read<AuthBloc>
     print('🔍 [2] QuickActions - teacherId: "$teacherId"');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ActionCard(
                    icon: Icons.fact_check,
                    title: 'Faire l\'appel',
                    color: AppTheme.violet,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.teacherAttendanceClasses),
                  ),
                  const SizedBox(width: 12),
                  _ActionCard(
                    icon: Icons.assignment_add,
                    title: 'Saisir Note',
                    color: AppTheme.teal,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.teacherGradesClasses),
                  ),
                  const SizedBox(width: 12),
                  _ActionCard(
                    icon: Icons.comment,
                    title: 'Commentaires',
                    color: AppTheme.sunshine,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.teacherCommentsClasses),
                  ),
                  const SizedBox(width: 12),
                  _ActionCard(
                    icon: Icons.event_note,
                    title: 'Cahier de texte',
                    color: Colors.pink,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _ActionCard(
                    icon: Icons.analytics,
                    title: 'Rapports',
                    color: AppTheme.violetLight,
                    onTap: () {
                      print('🔍 Clic Rapports - teacherId: "$teacherId"');
                      if (teacherId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherReportsPage(
                              teacherId: teacherId,
                              schoolId: schoolId,
                              subject: '',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erreur: Non authentifié')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bisDark),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: AppTheme.nightBlue,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}