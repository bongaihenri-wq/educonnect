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
          // Commentaire individuel → parent de l'élève
          parentsResponse = await _supabase
              .from('students')
              .select('parent_id')
              .eq('id', studentId)
              .eq('school_id', schoolId)
              .not('parent_id', 'is', null);
        } else {
          // Broadcast → tous les parents de la classe
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
      // Ne pas bloquer le flux principal
    }
  }

  // ============================================================
  // SAUVEGARDE COMMENTAIRE INDIVIDUEL — MISE À JOUR avec sender_id
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
        'sender_id': teacherId, // ✅ NOUVEAU
        'sender_role': 'teacher', // ✅ NOUVEAU
        'sender_name': senderName,
        'sender_type': 'teacher',
        'recipient_type': recipientType,
        'target_subject': targetSubject,
        'is_broadcast': false,
        'is_read': false,
        'author_type': 'teacher',
        'author_name': senderName,
      }).select('id');

      final commentId = (commentResponse as List).first['id'] as String;

      // ✅ NOUVEAU : Insérer les destinataires traçables
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

      debugPrint('✅ Commentaire sauvegardé - ID: $commentId, Enseignant: $senderName');
    } catch (e) {
      debugPrint('❌ Erreur commentaire: $e');
      throw Exception('Erreur sauvegarde commentaire: $e');
    }
  }

  // ============================================================
  // ENVOI NOTIFICATIONS INDIVIDUELLES — INCHANGÉ
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
  // BROADCAST — MISE À JOUR avec sender_id
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
        'sender_id': teacherId, // ✅ NOUVEAU
        'sender_role': 'teacher', // ✅ NOUVEAU
        'sender_name': senderName,
        'sender_type': 'teacher',
        'recipient_type': recipientType,
        'target_subject': targetSubject,
        'is_broadcast': true,
        'is_read': false,
        'author_type': 'teacher',
        'author_name': senderName,
      }).select('id');

      final commentId = (commentResponse as List).first['id'] as String;

      // ✅ NOUVEAU : Insérer les destinataires traçables
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

      debugPrint('✅ Broadcast envoyé - ID: $commentId, Classe: $className');
    } catch (e) {
      debugPrint('❌ Erreur broadcast: $e');
      throw Exception('Erreur envoi broadcast: $e');
    }
  }

  // ============================================================
  // NOTIFICATIONS BROADCAST — INCHANGÉ
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
  // RÉCUPÉRATION — Commentaires ACTIFS d'un élève — INCHANGÉ
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
        .eq('is_deleted', false) // ✅ NOUVEAU
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

  // ============================================================
  // RÉCUPÉRATION — Commentaires ACTIFS d'une classe — INCHANGÉ
  // ============================================================
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
        .eq('is_deleted', false) // ✅ NOUVEAU
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

  // ============================================================
  // RÉCUPÉRATION — TOUS les commentaires — INCHANGÉ
  // ============================================================
  Future<List<CommentModel>> getStudentAllComments(
    String studentId, {
    String? schoolId,
    int limit = 200,
  }) async {
    var query = _supabase
        .from('comments')
        .select()
        .eq('student_id', studentId)
        .eq('is_deleted', false); // ✅ NOUVEAU

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
  // ✅ NOUVEAU : Récupérer messages ENSEIGNANT (envoyés + reçus)
  // ============================================================
  Future<Map<String, List<Map<String, dynamic>>>> getTeacherMessages({
    required String teacherId,
    required String schoolId,
    int limit = 50,
  }) async {
    try {
      // 1. Messages ENVOYÉS par l'enseignant
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

      // 2. Messages REÇUS par l'enseignant (via message_recipients)
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
  // ✅ NOUVEAU : Récupérer TOUS les messages (ADMIN)
  // ============================================================
  Future<Map<String, List<Map<String, dynamic>>>> getAllMessages({
    required String schoolId,
    String? classId,
    String? senderRole,
    String? recipientRole,
    int limit = 100,
  }) async {
    try {
      // Requête de base
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

      // Filtre par classe
      if (classId != null && classId.isNotEmpty) {
        query = query.eq('class_id', classId);
      }

      // Filtre par rôle expéditeur
      if (senderRole != null && senderRole.isNotEmpty) {
        query = query.eq('sender_role', senderRole);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final allMessages = List<Map<String, dynamic>>.from(response as List);

      // Classer par rôle d'expéditeur
      final parentMessages = allMessages.where((m) => m['sender_role'] == 'parent').toList();
      final teacherMessages = allMessages.where((m) => m['sender_role'] == 'teacher').toList();
      final adminMessages = allMessages.where((m) => m['sender_role'] == 'admin').toList();

      // Classer par type (broadcast ou individuel)
      final broadcasts = allMessages.where((m) => m['is_broadcast'] == true).toList();
      final individuals = allMessages.where((m) => m['is_broadcast'] != true).toList();

      return {
        'all': allMessages,
        'parent': parentMessages,
        'teacher': teacherMessages,
        'admin': adminMessages,
        'broadcasts': broadcasts,
        'individuals': individuals,
      };
    } catch (e) {
      debugPrint('❌ Erreur getAllMessages: $e');
      return {
        'all': [],
        'parent': [],
        'teacher': [],
        'admin': [],
        'broadcasts': [],
        'individuals': [],
      };
    }
  }

  // ============================================================
  // ✅ NOUVEAU : Soft delete d'un message
  // ============================================================
  Future<void> softDeleteMessage({
    required String commentId,
    required String deletedBy,
  }) async {
    try {
      await _supabase.from('comments').update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toIso8601String(),
        'deleted_by': deletedBy,
      }).eq('id', commentId);

      debugPrint('✅ Message $commentId soft-deleted par $deletedBy');
    } catch (e) {
      debugPrint('❌ Erreur soft delete: $e');
      throw Exception('Erreur suppression message: $e');
    }
  }

  // ============================================================
  // ✅ NOUVEAU : Marquer comme lu pour un destinataire spécifique
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
  // ✅ NOUVEAU : Compter les lectures d'un message
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
  // ARCHIVAGE MANUEL — INCHANGÉ
  // ============================================================
  Future<void> archiveComment(String commentId) async {
    await _supabase.from('comments').update({
      'is_archived': true,
      'archived_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId);
  }

  // ============================================================
  // ARCHIVAGE AUTOMATIQUE — INCHANGÉ
  // ============================================================
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

  // ============================================================
  // RÉCUPÉRATION ARCHIVE — INCHANGÉ
  // ============================================================
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

  // ============================================================
  // MARQUER COMME LU (ancien) — INCHANGÉ pour compatibilité
  // ============================================================
  Future<void> markAsRead(String commentId) async {
    await _supabase.from('comments').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId);
  }

  // ============================================================
  // SUPPRESSION DÉFINITIVE — INCHANGÉ
  // ============================================================
  Future<void> deleteComment(String commentId) async {
    await _supabase.from('comments').delete().eq('id', commentId);
  }
}