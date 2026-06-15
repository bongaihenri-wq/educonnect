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
    String? className,
    DateTime? effectiveDate,
  }) async {
    if (schoolId.isEmpty) throw Exception('schoolId requis');
    if (teacherId.isEmpty) throw Exception('teacherId requis');
    if (content.trim().isEmpty) throw Exception('Commentaire vide');

    final now = DateTime.now();
    final expiresAt = effectiveDate ?? now.add(const Duration(days: 7));

    try {
      final recipientsString = recipients.join(',');

      String recipientType;
      if (recipients.contains('parent') && recipients.contains('admin')) {
        recipientType = 'parent,admin';
      } else if (recipients.contains('parent')) {
        recipientType = 'parent';
      } else if (recipients.contains('admin')) {
        recipientType = 'admin';
      } else {
        recipientType = recipients.first;
      }

      final commentResponse = await _supabase.from('comments').insert({
        'student_id': studentId,
        'class_id': classId,
        'teacher_id': teacherId,
        'school_id': schoolId,
        'content': content.trim(),
        'recipients': recipientsString,
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_archived': false,
        'sender_name': senderName,
        'sender_type': 'teacher',
        'recipient_type': recipientType,
        'target_subject': targetSubject,
        'is_broadcast': false,
        'is_read': false,
        'author_type': 'teacher',
        'author_name': senderName,
      }).select('id');

      final commentId = (commentResponse as List).first['id'];

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

      debugPrint('✅ Commentaire sauvegardé - Enseignant: $senderName, Matière: $targetSubject');
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
  // BROADCAST : Message à toute la classe
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
      final recipientsString = recipients.join(',');
      String recipientType;
      if (recipients.contains('parent') && recipients.contains('admin')) {
        recipientType = 'parent,admin';
      } else if (recipients.contains('parent')) {
        recipientType = 'parent';
      } else if (recipients.contains('admin')) {
        recipientType = 'admin';
      } else {
        recipientType = recipients.first;
      }

      final commentResponse = await _supabase.from('comments').insert({
        'student_id': null,
        'class_id': classId,
        'teacher_id': teacherId,
        'school_id': schoolId,
        'content': content.trim(),
        'recipients': recipientsString,
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_archived': false,
        'is_read': false,
        'sender_name': senderName,
        'sender_type': 'teacher',
        'recipient_type': recipientType,
        'target_subject': targetSubject,
        'is_broadcast': true,
        'author_type': 'teacher',
        'author_name': senderName,
      }).select('id');

      final commentId = (commentResponse as List).first['id'];

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

      debugPrint('✅ Broadcast envoyé à la classe $className');
    } catch (e) {
      debugPrint('❌ Erreur broadcast: $e');
      throw Exception('Erreur envoi broadcast: $e');
    }
  }

  // ============================================================
  // NOTIFICATIONS BROADCAST — CORRIGÉ type: 'general'
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
            'type': 'general', // ✅ CORRIGÉ : 'general' au lieu de 'broadcast'
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
          'type': 'general', // ✅ CORRIGÉ : 'general' au lieu de 'broadcast'
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
  // RÉCUPÉRATION — Commentaires ACTIFS d'un élève
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
  // RÉCUPÉRATION — Commentaires ACTIFS d'une classe
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
  // RÉCUPÉRATION — TOUS les commentaires
  // ============================================================
  Future<List<CommentModel>> getStudentAllComments(
    String studentId, {
    String? schoolId,
    int limit = 200,
  }) async {
    var query = _supabase
        .from('comments')
        .select()
        .eq('student_id', studentId);

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
  // ARCHIVAGE MANUEL
  // ============================================================
  Future<void> archiveComment(String commentId) async {
    await _supabase.from('comments').update({
      'is_archived': true,
      'archived_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId);
  }

  // ============================================================
  // ARCHIVAGE AUTOMATIQUE
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
  // RÉCUPÉRATION ARCHIVE
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
  // MARQUER COMME LU
  // ============================================================
  Future<void> markAsRead(String commentId) async {
    await _supabase.from('comments').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId);
  }

  // ============================================================
  // SUPPRESSION DÉFINITIVE
  // ============================================================
  Future<void> deleteComment(String commentId) async {
    await _supabase.from('comments').delete().eq('id', commentId);
  }
}