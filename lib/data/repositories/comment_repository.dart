// lib/data/repositories/comment_repository.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

class CommentRepository {
  final SupabaseClient _supabase;

  CommentRepository(this._supabase);

  // ============================================================
  // HELPER : Récupérer les IDs admin d'une école
  // ============================================================
  Future<List<String>> _getAdminUserIds(String schoolId) async {
    try {
      final roleRes = await _supabase.from('roles').select('id').eq('code', 'admin').maybeSingle();
      final adminRoleId = roleRes?['id'] as String?;
      if (adminRoleId == null) return [];

      final userRolesRes = await _supabase
          .from('user_roles')
          .select('user_id')
          .eq('role_id', adminRoleId);

      return (userRolesRes as List)
          .map((r) => r['user_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération admins: $e');
      return [];
    }
  }

  // ============================================================
  // HELPER : Construire recipient_type string
  // ============================================================
  String _buildRecipientType(List<String> recipients) {
    if (recipients.contains('parent') && recipients.contains('admin')) {
      return 'parent,admin';
    } else if (recipients.contains('parent')) {
      return 'parent';
    } else if (recipients.contains('admin')) {
      return 'admin';
    }
    return recipients.first;
  }

  // ============================================================
  // HELPER : Insérer les destinataires dans message_recipients
  // ============================================================
  Future<void> _insertMessageRecipients({
    required String commentId,
    required String classId,
    required String schoolId,
    required List<String> recipients,
    String? studentId,
  }) async {
    try {
      // Parents
      if (recipients.contains('parent')) {
        List<dynamic> parentsResponse;
        
        if (studentId != null) {
          parentsResponse = await _supabase
              .from('students')
              .select('parent_id')
              .eq('id', studentId)
              .eq('school_id', schoolId)
              .not('parent_id', 'is', null);
        } else {
          parentsResponse = await _supabase
              .from('students')
              .select('parent_id')
              .eq('class_id', classId)
              .eq('school_id', schoolId)
              .not('parent_id', 'is', null);
        }

        for (final link in parentsResponse) {
          final parentId = link['parent_id'] as String?;
          if (parentId != null) {
            await _supabase.from('message_recipients').insert({
              'comment_id': commentId,
              'recipient_id': parentId,
              'recipient_role': 'parent',
            });
          }
        }
      }

      // Admins
      if (recipients.contains('admin')) {
        final adminIds = await _getAdminUserIds(schoolId);
        for (final adminId in adminIds) {
          await _supabase.from('message_recipients').insert({
            'comment_id': commentId,
            'recipient_id': adminId,
            'recipient_role': 'admin',
          });
        }
      }

      debugPrint('✅ Destinataires enregistrés dans message_recipients');
    } catch (e) {
      debugPrint('❌ Erreur insertion destinataires: $e');
    }
  }

  // ============================================================
  // SAUVEGARDE COMMENTAIRE INDIVIDUEL
  // ============================================================
  Future<void> saveComment({
    required String studentId,
    required String classId,
    required String teacherId,
    required String schoolId,
    required String content,
    required List<String> recipients,
    required String studentName,
    required String senderName,
    required String targetSubject,
    required String senderRole,
    String? className,
    DateTime? effectiveDate,
  }) async {
    if (schoolId.isEmpty) throw Exception('schoolId requis');
    if (teacherId.isEmpty) throw Exception('teacherId requis');
    if (content.trim().isEmpty) throw Exception('Commentaire vide');

    final now = DateTime.now();
    final expiresAt = effectiveDate ?? now.add(const Duration(days: 7));

    try {
      final recipientType = _buildRecipientType(recipients);

      final commentResponse = await _supabase.from('comments').insert({
        'student_id': studentId,
        'class_id': classId,
        'teacher_id': teacherId,
        'school_id': schoolId,
        'content': content.trim(),
        'recipients': recipients.join(','),
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_archived': false,
        'is_deleted': false,
        'sender_id': teacherId,
        'sender_role': senderRole,
        'sender_name': senderName,
        'sender_type': senderRole,
        'recipient_type': recipientType,
        'target_subject': targetSubject,
        'is_broadcast': false,
        'is_read': false,
        'author_type': senderRole,
        'author_name': senderName,
      }).select('id');

      final commentId = (commentResponse as List).first['id'] as String;

      await _insertMessageRecipients(
        commentId: commentId,
        classId: classId,
        schoolId: schoolId,
        recipients: recipients,
        studentId: studentId,
      );

      await _sendNotifications(
        studentId: studentId,
        classId: classId,
        teacherId: teacherId,
        schoolId: schoolId,
        recipients: recipients,
        content: content.trim(),
        studentName: studentName,
        className: className,
        commentId: commentId,
        expiresAt: expiresAt,
      );

      debugPrint('✅ Commentaire sauvegardé - ID: $commentId, senderRole: $senderRole');
    } catch (e) {
      debugPrint('❌ Erreur commentaire: $e');
      throw Exception('Erreur sauvegarde commentaire: $e');
    }
  }

  // ============================================================
  // ENVOI NOTIFICATIONS INDIVIDUELLES
  // ============================================================
  Future<void> _sendNotifications({
    required String studentId,
    required String classId,
    required String teacherId,
    required String schoolId,
    required List<String> recipients,
    required String content,
    required String studentName,
    String? className,
    required String commentId,
    required DateTime expiresAt,
  }) async {
    final notifications = <Map<String, dynamic>>[];
    final now = DateTime.now().toIso8601String();

    if (recipients.contains('parent')) {
      final parentsResponse = await _supabase
          .from('students')
          .select('parent_id')
          .eq('id', studentId)
          .eq('school_id', schoolId)
          .not('parent_id', 'is', null);

      for (final link in parentsResponse as List) {
        if (link['parent_id'] != null) {
          notifications.add({
            'user_id': link['parent_id'],
            'title': 'Commentaire: $studentName',
            'content': '${className != null ? '$className - ' : ''}$content',
            'type': 'comment',
            'is_read': false,
            'created_at': now,
            'expires_at': expiresAt.toIso8601String(),
            'school_id': schoolId,
            'sender_id': teacherId,
            'reference_id': commentId,
          });
        }
      }
    }

    if (recipients.contains('admin')) {
      final adminIds = await _getAdminUserIds(schoolId);
      for (final adminId in adminIds) {
        notifications.add({
          'user_id': adminId,
          'title': 'Commentaire prof: $studentName',
          'content': '${className != null ? '$className - ' : ''}$content',
          'type': 'comment',
          'is_read': false,
          'created_at': now,
          'expires_at': expiresAt.toIso8601String(),
          'school_id': schoolId,
          'sender_id': teacherId,
          'reference_id': commentId,
        });
      }
    }

    if (notifications.isNotEmpty) {
      await _supabase.from('notifications').insert(notifications);
      debugPrint('✅ ${notifications.length} notifications envoyées');
    }
  }

  // ============================================================
  // BROADCAST
  // ============================================================
  Future<void> saveBroadcastComment({
    required String classId,
    required String teacherId,
    required String schoolId,
    required String content,
    required List<String> recipients,
    required String className,
    required String senderName,
    required String targetSubject,
    required String senderRole,
    DateTime? effectiveDate,
  }) async {
    if (schoolId.isEmpty) throw Exception('schoolId requis');
    if (teacherId.isEmpty) throw Exception('teacherId requis');
    if (content.trim().isEmpty) throw Exception('Message vide');

    final now = DateTime.now();
    final expiresAt = effectiveDate ?? now.add(const Duration(days: 7));

    try {
      final recipientType = _buildRecipientType(recipients);

      final commentResponse = await _supabase.from('comments').insert({
        'student_id': null,
        'class_id': classId,
        'teacher_id': teacherId,
        'school_id': schoolId,
        'content': content.trim(),
        'recipients': recipients.join(','),
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_archived': false,
        'is_deleted': false,
        'sender_id': teacherId,
        'sender_role': senderRole,
        'sender_name': senderName,
        'sender_type': senderRole,
        'recipient_type': recipientType,
        'target_subject': targetSubject,
        'is_broadcast': true,
        'is_read': false,
        'author_type': senderRole,
        'author_name': senderName,
      }).select('id');

      final commentId = (commentResponse as List).first['id'] as String;

      await _insertMessageRecipients(
        commentId: commentId,
        classId: classId,
        schoolId: schoolId,
        recipients: recipients,
      );

      await _sendBroadcastNotifications(
        classId: classId,
        teacherId: teacherId,
        schoolId: schoolId,
        recipients: recipients,
        content: content.trim(),
        className: className,
        commentId: commentId,
        expiresAt: expiresAt,
      );

      debugPrint('✅ Broadcast envoyé - ID: $commentId, senderRole: $senderRole');
    } catch (e) {
      debugPrint('❌ Erreur broadcast: $e');
      throw Exception('Erreur envoi broadcast: $e');
    }
  }

  // ============================================================
  // NOTIFICATIONS BROADCAST
  // ============================================================
  Future<void> _sendBroadcastNotifications({
    required String classId,
    required String teacherId,
    required String schoolId,
    required List<String> recipients,
    required String content,
    String? className,
    required String commentId,
    required DateTime expiresAt,
  }) async {
    final notifications = <Map<String, dynamic>>[];
    final now = DateTime.now().toIso8601String();

    if (recipients.contains('parent')) {
      final studentsResponse = await _supabase
          .from('students')
          .select('id, first_name, last_name, parent_id')
          .eq('class_id', classId)
          .eq('school_id', schoolId)
          .not('parent_id', 'is', null);

      for (final student in studentsResponse as List) {
        if (student['parent_id'] != null) {
          notifications.add({
            'user_id': student['parent_id'],
            'title': 'Message classe: ${className ?? 'Votre classe'}',
            'content': '${student['first_name']} ${student['last_name']} - $content',
            'type': 'general',
            'is_read': false,
            'created_at': now,
            'expires_at': expiresAt.toIso8601String(),
            'school_id': schoolId,
            'sender_id': teacherId,
            'reference_id': commentId,
          });
        }
      }
    }

    if (recipients.contains('admin')) {
      final adminIds = await _getAdminUserIds(schoolId);
      for (final adminId in adminIds) {
        notifications.add({
          'user_id': adminId,
          'title': 'Broadcast prof: ${className ?? 'Classe'}',
          'content': content,
          'type': 'general',
          'is_read': false,
          'created_at': now,
          'expires_at': expiresAt.toIso8601String(),
          'school_id': schoolId,
          'sender_id': teacherId,
          'reference_id': commentId,
        });
      }
    }

    if (notifications.isNotEmpty) {
      await _supabase.from('notifications').insert(notifications);
      debugPrint('✅ ${notifications.length} notifications broadcast envoyées');
    }
  }

  // ============================================================
  // RÉCUPÉRATIONS
  // ============================================================
  Future<List<CommentModel>> getStudentActiveComments(
    String studentId, {
    String? schoolId,
    int limit = 50,
  }) async {
    final now = DateTime.now().toIso8601String();
    
    var query = _supabase
        .from('comments')
        .select()
        .eq('student_id', studentId)
        .eq('is_archived', false)
        .eq('is_deleted', false)
        .or('expires_at.is.null,expires_at.gte.$now');

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => CommentModel.fromJson(json))
        .toList();
  }

  Future<List<CommentModel>> getClassActiveComments(
    String classId, {
    String? schoolId,
    int limit = 100,
  }) async {
    final now = DateTime.now().toIso8601String();
    
    var query = _supabase
        .from('comments')
        .select()
        .eq('class_id', classId)
        .eq('is_archived', false)
        .eq('is_deleted', false)
        .or('expires_at.is.null,expires_at.gte.$now');

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => CommentModel.fromJson(json))
        .toList();
  }

  Future<List<CommentModel>> getStudentAllComments(
    String studentId, {
    String? schoolId,
    int limit = 200,
  }) async {
    var query = _supabase
        .from('comments')
        .select()
        .eq('student_id', studentId)
        .eq('is_deleted', false);

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => CommentModel.fromJson(json))
        .toList();
  }

  // ============================================================
  // Récupérer messages ENSEIGNANT
  // ============================================================
  Future<Map<String, List<Map<String, dynamic>>>> getTeacherMessages({
    required String teacherId,
    required String schoolId,
    int limit = 50,
  }) async {
    try {
      final sentResponse = await _supabase
          .from('comments')
          .select('''
            *,
            students(first_name, last_name, class_id, classes(name, level)),
            message_recipients(
              recipient_id,
              recipient_role,
              read_at,
              recipient:recipient_id(first_name, last_name)
            )
          ''')
          .eq('sender_id', teacherId)
          .eq('school_id', schoolId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(limit);

      final receivedResponse = await _supabase
          .from('comments')
          .select('''
            *,
            sender:sender_id(first_name, last_name, role),
            students(first_name, last_name, class_id, classes(name, level)),
            message_recipients!inner(
              recipient_id,
              recipient_role,
              read_at
            )
          ''')
          .eq('school_id', schoolId)
          .eq('is_deleted', false)
          .eq('message_recipients.recipient_id', teacherId)
          .order('created_at', ascending: false)
          .limit(limit);

      return {
        'sent': List<Map<String, dynamic>>.from(sentResponse as List),
        'received': List<Map<String, dynamic>>.from(receivedResponse as List),
      };
    } catch (e) {
      debugPrint('❌ Erreur getTeacherMessages: $e');
      return {'sent': [], 'received': []};
    }
  }

  // ============================================================
  // ✅ CORRIGÉ : Récupérer TOUS les messages — SANS relation FK admin_messages
  // ============================================================
  Future<Map<String, List<Map<String, dynamic>>>> getAllMessages({
    required String schoolId,
    String? classId,
    String? senderType,
    int limit = 100,
  }) async {
    try {
      // 1. Récupérer comments
      var query = _supabase
          .from('comments')
          .select('''
            *,
            sender:sender_id(first_name, last_name, role),
            students(first_name, last_name, class_id, classes(name, level)),
            message_recipients(
              recipient_id,
              recipient_role,
              read_at,
              recipient:recipient_id(first_name, last_name)
            )
          ''')
          .eq('school_id', schoolId)
          .eq('is_deleted', false);

      if (classId != null && classId.isNotEmpty) {
        query = query.eq('class_id', classId);
      }
      if (senderType != null && senderType.isNotEmpty) {
        query = query.eq('sender_type', senderType);
      }

      final commentsResponse = await query
          .order('created_at', ascending: false)
          .limit(limit);

      // 2. ✅ CORRIGÉ : Récupérer admin_messages SANS relation FK
      var adminQuery = _supabase
          .from('admin_messages')
          .select()  // ✅ Pas de relation FK, colonnes brutes uniquement
          .eq('school_id', schoolId)
          .eq('is_active', true);

      if (classId != null && classId.isNotEmpty) {
        adminQuery = adminQuery.eq('target_class_id', classId);
      }

      final adminResponse = await adminQuery
          .order('created_at', ascending: false)
          .limit(limit);

      // 3. ✅ CORRIGÉ : Normaliser admin_messages SANS target_class
      final normalizedAdmin = (adminResponse as List).map((msg) {
        return {
          'id': msg['id'],
          'content': '${msg['title'] ?? ''}\n${msg['content'] ?? ''}',
          'sender_id': null,
          'sender_role': 'admin',
          'sender_type': 'admin',
          'sender_name': msg['sender_name'] ?? 'Administration',
          'sender': {'first_name': 'Admin', 'last_name': 'istration', 'role': 'admin'},
          'created_at': msg['created_at'],
          'is_broadcast': msg['recipient_type']?.toString().contains('all') ?? false,
          'is_read': msg['is_read'] ?? true,
          'class_id': msg['target_class_id'],  // ✅ Valeur brute, pas de relation
          'students': null,
          'message_recipients': [],
          'priority': msg['priority'],
          'target_parent_id': msg['target_parent_id'],
          'target_teacher_id': msg['target_teacher_id'],
          'is_admin_message': true,
        };
      }).toList();

      // 4. Combiner
      final allComments = List<Map<String, dynamic>>.from(commentsResponse as List);
      final allMessages = [...allComments, ...normalizedAdmin];
      
      allMessages.sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] as String);
        final dateB = DateTime.parse(b['created_at'] as String);
        return dateB.compareTo(dateA);
      });

      final parentMessages = allMessages.where((m) => m['sender_type'] == 'parent').toList();
      final teacherMessages = allMessages.where((m) => m['sender_type'] == 'teacher').toList();
      final adminMessages = allMessages.where((m) => m['sender_type'] == 'admin').toList();

      return {
        'all': allMessages,
        'parent': parentMessages,
        'teacher': teacherMessages,
        'admin': adminMessages,
      };
    } catch (e) {
      debugPrint('❌ Erreur getAllMessages: $e');
      return {
        'all': [],
        'parent': [],
        'teacher': [],
        'admin': [],
      };
    }
  }

  // ============================================================
  // Soft delete (comments OU admin_messages)
  // ============================================================
  Future<void> softDeleteMessage({
    required String messageId,
    required String deletedBy,
    String? sourceTable,
  }) async {
    try {
      final table = sourceTable ?? (messageId.startsWith('adm_') ? 'admin_messages' : 'comments');
      final cleanId = messageId.startsWith('adm_') ? messageId.substring(4) : messageId;

      if (table == 'admin_messages') {
        await _supabase.from('admin_messages').update({
          'is_active': false,
          'deleted_at': DateTime.now().toIso8601String(),
          'deleted_by': deletedBy,
        }).eq('id', cleanId);
      } else {
        await _supabase.from('comments').update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
          'deleted_by': deletedBy,
        }).eq('id', cleanId);
      }

      debugPrint('✅ Message $messageId soft-deleted dans $table par $deletedBy');
    } catch (e) {
      debugPrint('❌ Erreur soft delete: $e');
      throw Exception('Erreur suppression message: $e');
    }
  }

  // ============================================================
  // Marquer comme lu pour un destinataire spécifique
  // ============================================================
  Future<void> markRecipientAsRead({
    required String commentId,
    required String recipientId,
  }) async {
    try {
      await _supabase
          .from('message_recipients')
          .update({
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('comment_id', commentId)
          .eq('recipient_id', recipientId);
      
      debugPrint('✅ Message $commentId marqué comme lu pour $recipientId');
    } catch (e) {
      debugPrint('❌ Erreur markAsRead: $e');
    }
  }

  // ============================================================
  // Compter les lectures d'un message
  // ============================================================
  Future<Map<String, dynamic>> getMessageReadStats(String commentId) async {
    try {
      final recipients = await _supabase
          .from('message_recipients')
          .select('recipient_id, read_at')
          .eq('comment_id', commentId);

      final total = (recipients as List).length;
      final read = (recipients as List).where((r) => r['read_at'] != null).length;

      return {
        'total': total,
        'read': read,
        'unread': total - read,
        'percentage': total > 0 ? (read / total * 100).round() : 0,
      };
    } catch (e) {
      debugPrint('❌ Erreur getMessageReadStats: $e');
      return {'total': 0, 'read': 0, 'unread': 0, 'percentage': 0};
    }
  }

  // ============================================================
  // ARCHIVAGE
  // ============================================================
  Future<void> archiveComment(String commentId) async {
    await _supabase.from('comments').update({
      'is_archived': true,
      'archived_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId);
  }

  Future<int> archiveExpiredComments() async {
    try {
      final response = await _supabase.rpc('archive_expired_comments', params: {
        'p_now': DateTime.now().toIso8601String(),
      });
      
      final count = response as int? ?? 0;
      debugPrint('✅ $count commentaires archivés');
      return count;
    } catch (e) {
      debugPrint('❌ Erreur archivage: $e');
      return 0;
    }
  }

  Future<List<CommentModel>> getStudentArchivedComments(
    String studentId, {
    String? schoolId,
    int limit = 100,
  }) async {
    var query = _supabase
        .from('comments_archive')
        .select()
        .eq('student_id', studentId);

    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.eq('school_id', schoolId);
    }

    final response = await query
        .order('archived_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => CommentModel.fromJson(json))
        .toList();
  }

  Future<void> markAsRead(String commentId) async {
    await _supabase.from('comments').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId);
  }

  Future<void> deleteComment(String commentId) async {
    await _supabase.from('comments').delete().eq('id', commentId);
  }
}