// lib/services/parent_message_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ParentMessageService {
  final _client = Supabase.instance.client;

  // ============================================
  // ✅ CORRIGÉ : Fusion manuelle comments + admin_messages SANS FK
  // ============================================
  Future<List<Map<String, dynamic>>> getParentMessages({
    required String studentId,
    required String schoolId,
    String? classId,
    int limit = 100,
  }) async {
    try {
      print('🔍 [getParentMessages] studentId=$studentId, schoolId=$schoolId, classId=$classId');

      // 1. Récupérer la classe de l'élève
      String? studentClassId = classId;
      try {
        final studentRes = await _client
            .from('students')
            .select('class_id, parent_id')
            .eq('id', studentId)
            .eq('school_id', schoolId)
            .maybeSingle();
        
        if (studentRes != null) {
          studentClassId = studentRes['class_id'] as String?;
          print('✅ [getParentMessages] Classe élève: $studentClassId');
        } else {
          print('⚠️ [getParentMessages] Élève non trouvé');
        }
      } catch (e) {
        print('⚠️ [getParentMessages] Erreur récupération classe: $e');
      }

      // 2. Récupérer TOUS les comments pour cette école et classe
      List<dynamic> allComments = [];
      try {
        final response = await _client
            .from('comments')
            .select('''
              *,
              students(first_name, last_name, class_id, classes(name, level))
            ''')
            .eq('school_id', schoolId)
            .eq('is_deleted', false)
            .eq('class_id', studentClassId ?? '')
            .order('created_at', ascending: false)
            .limit(limit * 2);

        allComments = response;
        print('✅ [getParentMessages] Comments bruts: ${allComments.length}');
      } catch (e) {
        print('❌ [getParentMessages] Erreur comments: $e');
      }

      // 3. ✅ CORRIGÉ : Récupérer admin_messages SANS relation FK
      List<dynamic> adminResponse = [];
      try {
        var adminQuery = _client
            .from('admin_messages')
            .select()  // ✅ Pas de relation FK, colonnes brutes uniquement
            .eq('school_id', schoolId)
            .eq('is_active', true);

        if (studentClassId != null && studentClassId.isNotEmpty) {
          adminQuery = adminQuery.or('target_class_id.eq.$studentClassId,target_class_id.is.null');
        }

        adminResponse = await adminQuery
            .order('created_at', ascending: false)
            .limit(limit);

        print('✅ [getParentMessages] Admin messages: ${adminResponse.length}');
      } catch (e) {
        print('❌ [getParentMessages] Erreur admin_messages: $e');
      }

      // 4. Normaliser et fusionner
      final List<Map<String, dynamic>> unified = [];

      // Normaliser comments
      for (final msg in allComments) {
        final msgMap = msg as Map<String, dynamic>;
        final senderType = (msgMap['sender_type'] as String?)?.trim() ?? 
                          (msgMap['sender_role'] as String?)?.trim() ?? 
                          'teacher';
        
        final msgStudentId = msgMap['student_id'] as String?;
        final recipientType = msgMap['recipient_type'] as String? ?? '';
        
        final isForThisStudent = msgStudentId == studentId;
        final isBroadcast = msgStudentId == null;
        final isSentByParent = senderType == 'parent';
        
        final isVisible = isForThisStudent || isBroadcast || isSentByParent;
        final isRecipientParent = recipientType.contains('parent') || 
                                recipientType.contains('all') ||
                                isSentByParent;

        if (isVisible && isRecipientParent) {
          unified.add({
            'message_id': msgMap['id'] as String,
            'message_type': 'comment',
            'content': msgMap['content'] as String? ?? '',
            'sender_type': senderType,
            'sender_name': msgMap['sender_name'] as String? ?? 'Inconnu',
            'sender_role': msgMap['sender_role'] as String? ?? 'teacher',
            'recipient_type': recipientType,
            'created_at': msgMap['created_at'] as String,
            'is_read': msgMap['is_read'] as bool? ?? true,
            'expires_at': msgMap['expires_at'] as String?,
            'target_subject': msgMap['target_subject'] as String?,
            'parent_reply': msgMap['parent_reply'] as String?,
            'teacher_id': msgMap['teacher_id'] as String?,
            'student_id': msgMap['student_id'] as String?,
            'class_id': msgMap['class_id'] as String?,
            'school_id': msgMap['school_id'] as String?,
            'is_broadcast': msgMap['is_broadcast'] as bool? ?? false,
            'source_table': 'comments',
            'students': msgMap['students'],
            'priority': null,
          });
        }
      }

      // Normaliser admin_messages
      for (final msg in adminResponse) {
        final msgMap = msg as Map<String, dynamic>;
        
        final targetClassId = msgMap['target_class_id'] as String?;
        final recipientType = msgMap['recipient_type'] as String? ?? 'all_users';
        
        final isRelevant = targetClassId == null || targetClassId == studentClassId;

        if (isRelevant) {
          unified.add({
            'message_id': 'adm_${msgMap['id'] as String}',
            'message_type': 'admin_message',
            'content': '${msgMap['title'] as String? ?? ''}\n${msgMap['content'] as String? ?? ''}',
            'sender_type': 'admin',
            'sender_name': msgMap['sender_name'] as String? ?? 'Administration',
            'sender_role': 'admin',
            'recipient_type': recipientType,
            'created_at': msgMap['created_at'] as String,
            'is_read': msgMap['is_read'] as bool? ?? true,
            'expires_at': msgMap['expires_at'] as String?,
            'target_subject': null,
            'parent_reply': null,
            'teacher_id': null,
            'student_id': null,
            'class_id': msgMap['target_class_id'] as String?,
            'school_id': msgMap['school_id'] as String?,
            'is_broadcast': true,
            'source_table': 'admin_messages',
            'students': null,
            'priority': msgMap['priority'] as String?,
          });
        }
      }

      // Trier par date décroissante
      unified.sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] as String);
        final dateB = DateTime.parse(b['created_at'] as String);
        return dateB.compareTo(dateA);
      });

      print('✅ [getParentMessages] Total unifié: ${unified.length}');
      for (final m in unified) {
        final content = m['content'] as String? ?? '';
        final preview = content.length > 30 ? content.substring(0, 30) + '...' : content;
        print('  - [${m['sender_type']}] ${m['sender_name']} | ${m['message_type']} | "$preview"');
      }

      return unified;

    } catch (e) {
      print('❌ [getParentMessages] Erreur globale: $e');
      return [];
    }
  }

  // ============================================
  // MARQUER comme lu
  // ============================================
  Future<void> markAsRead(String messageId, String messageType) async {
    print('🔍 [markAsRead] messageId=$messageId, type=$messageType');
    
    final table = _getTableFromType(messageType);
    final id = _getIdFromMessageId(messageId, messageType);
    
    print('🔍 [markAsRead] table=$table, cleanId=$id');
    
    try {
      if (table == 'comments') {
        await _client.from('comments').update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
        print('✅ [markAsRead] Comment marqué lu');
      } else if (table == 'admin_messages') {
        await _client.from('admin_messages').update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
        print('✅ [markAsRead] Admin message marqué lu');
      }
    } catch (e) {
      print('❌ [markAsRead] Erreur: $e');
    }
  }

  // ============================================
  // RÉPONDRE
  // ============================================
  Future<void> replyToComment(String commentId, String reply) async {
    final cleanId = commentId.replaceFirst('adm_', '');
    
    await _client.from('comments').update({
      'parent_reply': reply,
      'replied_at': DateTime.now().toIso8601String(),
      'is_read': false,
    }).eq('id', cleanId);
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