// lib/presentation/pages/parent/widgets/comments/comment_item.dart
import 'package:flutter/material.dart';
import '/../../config/theme.dart';

class CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;
  final String parentName;
  final Function(String commentId, String? teacherId, String content) onReply;

  const CommentItem({
    super.key,
    required this.comment,
    required this.parentName,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final content = comment['content'] as String? ?? 'Aucun contenu';
    final date = DateTime.parse(comment['created_at'] as String);
    final expiresAt = comment['expires_at'] != null 
        ? DateTime.parse(comment['expires_at'] as String) 
        : null;
    final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);
    final parentReply = comment['parent_reply'] as String?;
    final senderName = comment['sender_name'] as String? ?? 'Enseignant';
    final senderType = comment['sender_type'] as String? ?? 'teacher';
    final targetSubject = comment['target_subject'] as String?;
    final isBroadcast = comment['is_broadcast'] as bool? ?? false;
    final isRead = comment['is_read'] as bool? ?? true;

    final isFromTeacher = senderType == 'teacher';
    final displayName = isFromTeacher 
        ? (senderName != 'Enseignant' ? senderName : 'Professeur')
        : (senderType == 'parent' ? 'Vous' : 'Administration');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.bisDark),
        boxShadow: isRead ? null : [
          BoxShadow(
            color: AppTheme.violet.withOpacity(0.15),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(displayName, isFromTeacher, targetSubject, isBroadcast, date, isRead),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, color: AppTheme.nightBlue)),
          if (expiresAt != null) _buildExpiry(expiresAt, isExpired),
          if (parentReply != null && parentReply.isNotEmpty) _buildParentReply(parentReply),
          if ((parentReply == null || parentReply.isEmpty) && isFromTeacher && !isExpired)
            _buildReplyButton(context, comment['id'] as String, comment['teacher_id'] as String?, content),
        ],
      ),
    );
  }

  Widget _buildHeader(String displayName, bool isFromTeacher, String? targetSubject, bool isBroadcast, DateTime date, bool isRead) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isFromTeacher ? AppTheme.violet.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFromTeacher ? Icons.school : Icons.person,
            color: isFromTeacher ? AppTheme.violet : Colors.green,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.nightBlue)),
                  if (!isRead) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              if (targetSubject != null && targetSubject.isNotEmpty)
                Text(
                  isBroadcast ? 'À tous • ${_capitalize(targetSubject)}' : 'Matière: ${_capitalize(targetSubject)}',
                  style: TextStyle(fontSize: 10, color: AppTheme.violet),
                ),
              Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}', 
                   style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isFromTeacher ? AppTheme.violet.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isFromTeacher ? 'Professeur' : 'Parent',
            style: TextStyle(color: isFromTeacher ? AppTheme.violet : Colors.green, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiry(DateTime expiresAt, bool isExpired) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(isExpired ? Icons.timer_off : Icons.timer, size: 12, color: isExpired ? Colors.red : Colors.grey),
          const SizedBox(width: 4),
          Text(
            isExpired 
                ? 'Expiré le ${expiresAt.day.toString().padLeft(2, '0')}/${expiresAt.month.toString().padLeft(2, '0')}/${expiresAt.year}'
                : 'Valide jusqu\'au ${expiresAt.day.toString().padLeft(2, '0')}/${expiresAt.month.toString().padLeft(2, '0')}/${expiresAt.year}',
            style: TextStyle(fontSize: 10, color: isExpired ? Colors.red : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildParentReply(String parentReply) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply, size: 12, color: Colors.green),
              const SizedBox(width: 4),
              Text('Votre réponse', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 4),
          Text(parentReply, style: TextStyle(fontSize: 12, color: AppTheme.nightBlue)),
        ],
      ),
    );
  }

  Widget _buildReplyButton(BuildContext context, String commentId, String? teacherId, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => onReply(commentId, teacherId, content),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.violet.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.violet.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.reply, size: 14, color: AppTheme.violet),
              const SizedBox(width: 4),
              Text('Répondre', style: TextStyle(fontSize: 11, color: AppTheme.violet, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}