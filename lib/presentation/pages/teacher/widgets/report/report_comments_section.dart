// lib/presentation/pages/teacher/widgets/report/report_comments_section.dart
import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';

class ReportCommentsSection extends StatelessWidget {
  const ReportCommentsSection({super.key});

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Icon(Icons.comment_outlined, size: 18, color: AppTheme.violet),
                const SizedBox(width: 8),
                Text(
                  'Commentaires',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.nightBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // TODO: Liste des commentaires
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bis,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Aucun commentaire pour cette période',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Bouton ajouter
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Ouvrir dialog ajout commentaire
                },
                icon: Icon(Icons.add, size: 18, color: AppTheme.violet),
                label: Text('Ajouter un commentaire', style: TextStyle(color: AppTheme.violet)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.violet),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}