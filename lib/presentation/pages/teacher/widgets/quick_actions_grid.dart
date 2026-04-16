import 'package:flutter/material.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildListDelegate([
          _ActionCard(
            icon: Icons.fact_check,
            title: 'Faire l\'appel',
            color: AppTheme.violet,
            // On navigue vers la page d'appel qui gérera sa propre logique
            onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
          ),
          _ActionCard(
            icon: Icons.assignment_add,
            title: 'Saisir Note',
            color: AppTheme.teal,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Module de notes bientôt disponible")),
              );
            },
          ),
          _ActionCard(
            icon: Icons.event_note,
            title: 'Cahier de texte',
            color: AppTheme.sunshine,
            onTap: () {},
          ),
          _ActionCard(
            icon: Icons.analytics,
            title: 'Rapports',
            color: AppTheme.violetLight,
            onTap: () {},
          ),
        ]),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.bisDark),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Le cercle de couleur en fond d'icône (Ton design original)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.nightBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}