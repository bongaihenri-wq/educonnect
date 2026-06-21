// lib/presentation/pages/admin/widgets/admin_quick_actions.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class AdminQuickActions extends StatelessWidget {
  const AdminQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilotage Établissement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.nightBlue,
            ),
          ),
          const SizedBox(height: 16),
          
          // Ligne 1 : Gestion académique
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // ✅ FUSIONNÉ : Classes & Élèves (supprime Liste Classes + Liste Élèves)
                _quickAccessButton(context, Icons.people_alt, 'Classes &\nÉlèves', Colors.indigo, '/admin/classes-students'),
                const SizedBox(width: 12),
                _quickAccessButton(context, Icons.person_outline, 'Enseignants', Colors.orange, '/admin/teachers'),
                const SizedBox(width: 12),
                _quickAccessButton(context, Icons.family_restroom, 'Parents', Colors.pink, '/admin/parents'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Ligne 2 : Pédagogie & Planning
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickAccessButton(context, Icons.calendar_today, 'Emploi du\ntemps', Colors.teal, '/schedule'),
                const SizedBox(width: 12),
                _quickAccessButton(context, Icons.assignment, 'Devoirs', Colors.deepOrange, '/homework'),
                const SizedBox(width: 12),
                _quickAccessButton(context, Icons.bar_chart, 'Notes', Colors.purple, '/grades'),
                const SizedBox(width: 12),
                _quickAccessButton(context, Icons.fact_check, 'Notes en\nattente', Colors.red, '/admin/grades-pending'),
                const SizedBox(width: 12),
                _quickAccessButton(context, Icons.analytics, 'Rapports', Colors.cyan, '/admin/reports'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Actions avancées

          _buildActionTile(
           icon: Icons.campaign,
           label: 'Envoyer un message',
           color: Colors.purple,
           onTap: () => Navigator.pushNamed(context, '/admin/send-message'),
              ),
        const SizedBox(height: 12),
           _buildActionTile(
            icon: Icons.settings,
            label: 'Paramètres École',
            color: Colors.grey,
            onTap: () => Navigator.pushNamed(context, '/admin/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _quickAccessButton(BuildContext context, IconData icon, String label, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
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