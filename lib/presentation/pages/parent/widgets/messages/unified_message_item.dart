// lib/presentation/pages/parent/widgets/messages/unified_message_item.dart
import 'package:flutter/material.dart';
import '/../../config/theme.dart';

class UnifiedMessageItem extends StatelessWidget {
  final Map<String, dynamic> message;
  final String parentName;
  final Function(String messageId, String? teacherId, String content, String type) onReply;
  final Function(String messageId, String type) onMarkRead;

  const UnifiedMessageItem({
    super.key,
    required this.message,
    required this.parentName,
    required this.onReply,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final messageType = message['message_type'] as String? ?? 'comment';
    final content = message['content'] as String? ?? 'Aucun contenu';
    final createdAtRaw = message['created_at'] as String?;
    final createdAt = createdAtRaw != null ? DateTime.parse(createdAtRaw) : DateTime.now();
    final expiresAt = message['expires_at'] != null 
        ? DateTime.parse(message['expires_at'] as String) 
        : null;
    final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);
    final isRead = message['is_read'] as bool? ?? true;
    final senderName = message['sender_name'] as String? ?? 'Expéditeur';
    final senderType = message['sender_type'] as String? ?? 'teacher';
    final targetSubject = message['target_subject'] as String?;
    final daysUntil = message['days_until'] as int?;
    final homeworkType = message['homework_type'] as String?;
    final dueDate = message['due_date'] as String?;
    final parentReply = message['parent_reply'] as String?;
    final teacherId = message['teacher_id'] as String?;
    final messageId = message['message_id'] as String? ?? message['id'] as String? ?? '';
    final priority = message['priority'] as String?;

    // ✅ FIX : Si pas d'ID, on n'affiche rien
    if (messageId.isEmpty) return const SizedBox.shrink();

    final (icon, color, label) = _getTypeInfo(messageType, homeworkType, priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRead ? AppTheme.bisDark : color.withOpacity(0.5),
          width: isRead ? 1 : 2,
        ),
        boxShadow: isRead ? null : [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(senderName, senderType, targetSubject, label, color, icon, isRead, createdAt),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, color: AppTheme.nightBlue)),
          
          if (messageType == 'homework' && daysUntil != null)
            _buildHomeworkBadge(daysUntil, dueDate, color),
          
          if (expiresAt != null) _buildExpiry(expiresAt, isExpired),
          
          if (parentReply != null && parentReply.isNotEmpty) 
            _buildParentReply(parentReply),
          
          // ✅ FIX : messageId est maintenant String non-null
          if (messageType == 'comment' && (parentReply == null || parentReply.isEmpty) && !isExpired)
            _buildReplyButton(context, messageId, teacherId, content),
          
          if ((messageType == 'homework' || messageType == 'admin_message') && !isRead)
            _buildMarkReadButton(context, messageId, messageType),
        ],
      ),
    );
  }

  (IconData, Color, String) _getTypeInfo(String type, String? homeworkType, String? priority) {
    switch (type) {
      case 'homework':
        final hwType = homeworkType ?? 'devoir';
        return switch (hwType) {
          'examen' => (Icons.assignment_late, Colors.red, 'Examen'),
          'controle' => (Icons.assignment, Colors.orange, 'Contrôle'),
          'interro' => (Icons.quiz, Colors.blue, 'Interro'),
          _ => (Icons.assignment_turned_in, Colors.green, 'Devoir'),
        };
      case 'admin_message':
        final p = priority ?? 'normal';
        return switch (p) {
          'urgent' => (Icons.campaign, Colors.red, 'Urgent'),
          'high' => (Icons.campaign, Colors.orange, 'Important'),
          _ => (Icons.campaign, Colors.purple, 'Administration'),
        };
      case 'comment':
      default:
        return (Icons.school, AppTheme.violet, 'Professeur');
    }
  }

  Widget _buildHeader(
    String senderName,
    String senderType,
    String? targetSubject,
    String label,
    Color color,
    IconData icon,
    bool isRead,
    DateTime createdAt,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.nightBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isRead) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              if (targetSubject != null)
                Text(
                  '$label • ${_capitalize(targetSubject)}',
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
                ),
              // ✅ MISE EN ÉVIDENCE DATE + HEURE
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.bisLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 10, color: AppTheme.violet),
                    const SizedBox(width: 4),
                    Text(
                      '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} à ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.violet,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeworkBadge(int daysUntil, String? dueDate, Color color) {
    final isUrgent = daysUntil <= 1;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isUrgent ? Colors.red.withOpacity(0.1) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isUrgent ? Colors.red.withOpacity(0.3) : color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUrgent ? Icons.warning : Icons.calendar_today,
              size: 12,
              color: isUrgent ? Colors.red : color,
            ),
            const SizedBox(width: 4),
            Text(
              isUrgent 
                  ? 'J-$daysUntil • À rendre demain !'
                  : 'J-$daysUntil • À rendre le $dueDate',
              style: TextStyle(
                fontSize: 10,
                color: isUrgent ? Colors.red : color,
                fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiry(DateTime expiresAt, bool isExpired) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            size: 12,
            color: isExpired ? Colors.red : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired 
                ? 'Expiré le ${expiresAt.day.toString().padLeft(2, '0')}/${expiresAt.month.toString().padLeft(2, '0')}'
                : 'Valide jusqu\'au ${expiresAt.day.toString().padLeft(2, '0')}/${expiresAt.month.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 10,
              color: isExpired ? Colors.red : Colors.grey.shade600,
            ),
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
              Text(
                'Votre réponse',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            parentReply,
            style: const TextStyle(fontSize: 12, color: AppTheme.nightBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyButton(BuildContext context, String messageId, String? teacherId, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => onReply(messageId, teacherId, content, 'comment'),
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
              Text(
                'Répondre',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.violet,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkReadButton(BuildContext context, String messageId, String type) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => onMarkRead(messageId, type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                'Marquer comme lu',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
