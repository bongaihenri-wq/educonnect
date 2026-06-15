// lib/services/parent_message_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ParentMessageService {
  final _client = Supabase.instance.client;

  // ============================================
  // RÉCUPÉRER tous les messages (comments + devoirs + admin)
  // ============================================
  Future<List<Map<String, dynamic>>> getParentMessages({
    required String studentId,
    required String schoolId,
    String? classId,
    int limit = 100,
  }) async {
    try {
      final response = await _client.rpc('get_parent_messages', params: {
        'p_student_id': studentId,
        'p_school_id': schoolId,
        'p_class_id': classId,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback : requête directe sur la vue
      final response = await _client
          .from('parent_messages')
          .select()
          .eq('school_id', schoolId)
          .or('student_id.eq.$studentId,student_id.is.null')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    }
  }

  // ============================================
  // MARQUER comme lu
  // ============================================
  Future<void> markAsRead(String messageId, String messageType) async {
    final table = _getTableFromType(messageType);
    final id = _getIdFromMessageId(messageId, messageType);
    
    if (table == 'comments') {
      await _client.from('comments').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } else if (table == 'admin_messages') {
      await _client.from('admin_messages').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    }
    // homeworks : pas de "lu", on garde la date
  }

  // ============================================
  // RÉPONDRE (uniquement pour comments)
  // ============================================
  Future<void> replyToComment(String commentId, String reply) async {
    await _client.from('comments').update({
      'parent_reply': reply,
      'replied_at': DateTime.now().toIso8601String(),
      'is_read': false, // Pour notifier l'enseignant
    }).eq('id', commentId);
  }

  // ============================================
  // COMPTEUR messages non lus
  // ============================================
  Future<int> getUnreadCount({
    required String studentId,
    required String schoolId,
  }) async {
    final messages = await getParentMessages(
      studentId: studentId,
      schoolId: schoolId,
    );
    
    return messages.where((m) {
      final isRead = m['is_read'] as bool? ?? false;
      final expiresAt = m['expires_at'] as String?;
      final isExpired = expiresAt != null 
          ? DateTime.parse(expiresAt).isBefore(DateTime.now())
          : false;
      return !isRead && !isExpired;
    }).length;
  }

  String _getTableFromType(String type) {
    switch (type) {
      case 'comment': return 'comments';
      case 'admin_message': return 'admin_messages';
      case 'homework': return 'homeworks';
      default: return 'comments';
    }
  }

  String _getIdFromMessageId(String messageId, String type) {
    if (messageId.startsWith('hw_')) return messageId.substring(3);
    if (messageId.startsWith('adm_')) return messageId.substring(4);
    return messageId;
  }
}