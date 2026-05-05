// lib/presentation/pages/parent/widgets/comments_tab.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'common_widgets.dart';

class CommentsTab extends StatelessWidget {
  final List<Map<String, dynamic>> comments;

  const CommentsTab({super.key, required this.comments});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonWidgets.buildSectionTitle('Commentaires des enseignants'),
          const SizedBox(height: 12),
          
          if (comments.isEmpty)
            CommonWidgets.buildEmptyState('Aucun commentaire pour le moment')
          else
            ...comments.map((c) => _buildCommentItem(c)),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final author = comment['app_users'];
    final authorName = author != null 
        ? '${author['first_name']} ${author['last_name']}'
        : 'Enseignant';
    final role = author?['role'] ?? 'teacher';
    final date = DateTime.parse(comment['created_at']);

    Color roleColor;
    switch (role) {
      case 'admin':
        roleColor = Colors.red;
        break;
      case 'teacher':
        roleColor = AppTheme.violet;
        break;
      default:
        roleColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bisDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role == 'admin' ? Icons.admin_panel_settings : Icons.school,
                  color: roleColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.nightBlue,
                      ),
                    ),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.nightBlueLight.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role == 'admin' ? 'Admin' : 'Professeur',
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment['content'] ?? 'Aucun contenu',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.nightBlue,
            ),
          ),
        ],
      ),
    );
  }
}
