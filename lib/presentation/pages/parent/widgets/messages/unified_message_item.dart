// lib/presentation/pages/parent/widgets/messages/unified_message_item.dart
import 'package:flutter/material.dart';
import 'package:educonnect/config/theme.dart';

class UnifiedMessageItem extends StatelessWidget {
  final Map<String, dynamic> message;
  final String parentName;
  final Function(
      String messageId, String? teacherId, String content, String type) onReply;
  final Function(String messageId, String type) onMarkRead;

  const UnifiedMessageItem({
    super.key,
    required this.message,
    required this.parentName,
    required this.onReply,
    required this.onMarkRead,
  });

  String get _messageType {
    final sourceTable = message['source_table'] as String? ?? 'comments';
    switch (sourceTable) {
      case 'admin_messages':
        return 'admin_message';
      case 'comments':
      default:
        return 'comment';
    }
  }

  String get _senderType {
    return message['sender_type'] as String? ?? 'teacher';
  }

  bool get _isReceived {
    return _senderType == 'teacher' || _senderType == 'admin';
  }

  bool get _isSent {
    return _senderType == 'parent';
  }

  String get _messageId {
    return message['message_id'] as String? ?? message['id'] as String? ?? '';
  }

  String? get _teacherId {
    return message['teacher_id'] as String?;
  }

  String get _content {
    return message['content'] as String? ?? '';
  }

  bool get _isUnread {
    return !(message['is_read'] as bool? ?? true);
  }

  Color get _senderColor {
    switch (_senderType) {
      case 'admin':
        return Colors.orange;
      case 'parent':
        return AppTheme.violet;
      case 'teacher':
      default:
        return Colors.blue;
    }
  }

  IconData get _senderIcon {
    switch (_senderType) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'parent':
        return Icons.person;
      case 'teacher':
      default:
        return Icons.school;
    }
  }

  String get _senderLabel {
    switch (_senderType) {
      case 'admin':
        return 'Admin';
      case 'parent':
        return 'Vous';
      case 'teacher':
      default:
        return 'Prof';
    }
  }

  @override
  Widget build(BuildContext context) {
    final senderName = message['sender_name'] as String? ?? 'Inconnu';
    final createdAt = message['created_at'] as String?;
    final targetSubject = message['target_subject'] as String?;
    final priority = message['priority'] as String?;
    final isBroadcast = message['is_broadcast'] as bool? ?? false;
    final parentReply = message['parent_reply'] as String?;

    return Dismissible(
      key: Key(_messageId),
      direction:
          _isReceived ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: (_) {
        onMarkRead(_messageId, _messageType);
      },
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: _isUnread ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _isUnread
                ? _senderColor.withOpacity(0.3)
                : Colors.grey.shade200,
            width: _isUnread ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: _isUnread && _isReceived
              ? () => onMarkRead(_messageId, _messageType)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _senderColor.withOpacity(0.1),
                      child: Icon(_senderIcon, color: _senderColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _senderType == 'parent' ? parentName : senderName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _isUnread
                                  ? Colors.black87
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildBadge(
                                text: _senderLabel,
                                color: _senderColor,
                              ),
                              if (isBroadcast)
                                _buildBadge(
                                  text: 'Broadcast',
                                  color: Colors.purple,
                                ),
                              if (priority != null && priority != 'normal')
                                _buildBadge(
                                  text: priority == 'high'
                                      ? 'Urgent'
                                      : 'Important',
                                  color: priority == 'high'
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (_isUnread && _isReceived) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _senderColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (targetSubject != null && targetSubject.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Matière: $targetSubject',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  _content,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isUnread ? Colors.black87 : Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                if (parentReply != null && parentReply.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.violet.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.violet.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.reply, size: 14, color: AppTheme.violet),
                            const SizedBox(width: 4),
                            Text(
                              'Votre réponse',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.violet,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          parentReply,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isUnread && _isReceived) ...[
                      TextButton.icon(
                        onPressed: () => onMarkRead(_messageId, _messageType),
                        icon: Icon(Icons.check_circle_outline,
                            size: 16, color: _senderColor),
                        label: Text(
                          'Marquer lu',
                          style: TextStyle(fontSize: 12, color: _senderColor),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_isReceived &&
                        _senderType == 'teacher' &&
                        _messageType == 'comment') ...[
                      TextButton.icon(
                        onPressed: () => onReply(
                            _messageId, _teacherId, _content, _messageType),
                        icon:
                            Icon(Icons.reply, size: 16, color: AppTheme.violet),
                        label: const Text(
                          'Répondre',
                          style:
                              TextStyle(fontSize: 12, color: AppTheme.violet),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return 'Il y a ${diff.inMinutes} min';
        }
        return 'Il y a ${diff.inHours}h';
      } else if (diff.inDays == 1) {
        return 'Hier';
      } else if (diff.inDays < 7) {
        final jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return jours[date.weekday - 1];
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
