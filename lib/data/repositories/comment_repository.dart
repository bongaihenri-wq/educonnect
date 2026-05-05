// lib/data/repositories/comment_repository.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

class CommentRepository {
  final SupabaseClient _supabase;

  CommentRepository(this._supabase);

  // ============================================================
  // SAUVEGARDE COMMENTAIRE AVEC DATE D'EFFET/EXPIRATION
  // ============================================================
  Future<void> saveComment({
    required String studentId,
    required String classId,
    required String teacherId,
    required String schoolId,
    required String content,
    required List<String> recipients,
    required String studentName,
    String? className,
    DateTime? effectiveDate, // ✅ Date d'effet = date d'expiration
  }) async {
    if (schoolId.isEmpty) throw Exception('schoolId requis');
    if (teacherId.isEmpty) throw Exception('teacherId requis');
    if (content.trim().isEmpty) throw Exception('Commentaire vide');

    final now = DateTime.now();
    
    // ✅ Date d'expiration = date d'effet (si fournie) sinon +7 jours par défaut
    final expiresAt = effectiveDate ?? now.add(const Duration(days: 7));

    try {
      final commentResponse = await _supabase.from('comments').insert({
        'student_id': studentId,
        'class_id': classId,
        'teacher_id': teacherId,
        'school_id': schoolId,
        'content': content.trim(),
        'recipients': recipients,
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(), // ✅ Date d'effet/expiration
        'is_archived': false,
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

      debugPrint('✅ Commentaire sauvegardé (expire le ${expiresAt.day}/${expiresAt.month})');
    } catch (e) {
      debugPrint('❌ Erreur commentaire: $e');
      throw Exception('Erreur sauvegarde commentaire: $e');
    }
  }

  // ============================================================
  // ENVOI NOTIFICATIONS (avec date d'expiration)
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
          .from('parent_students')
          .select('parent_id')
          .eq('student_id', studentId)
          .eq('school_id', schoolId);

      for (final link in parentsResponse as List) {
        notifications.add({
          'user_id': link['parent_id'],
          'title': 'Commentaire: $studentName',
          'content': '${className != null ? '$className - ' : ''}$content',
          'type': 'comment',
          'is_read': false,
          'created_at': now,
          'expires_at': expiresAt.toIso8601String(), // ✅ Propager l'expiration
          'school_id': schoolId,
          'sender_id': teacherId,
          'reference_id': commentId,      
        });
      }
    }

    if (recipients.contains('admin')) {
      final adminsResponse = await _supabase
          .from('app_users')
          .select('id')
          .eq('school_id', schoolId)
          .eq('role', 'admin');

      for (final admin in adminsResponse as List) {
        notifications.add({
          'user_id': admin['id'],
          'title': 'Commentaire prof: $studentName',
          'content': '${className != null ? '$className - ' : ''}$content',
          'type': 'comment',
          'is_read': false,
          'created_at': now,
          'expires_at': expiresAt.toIso8601String(), // ✅ Propager l'expiration
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
  // RÉCUPÉRATION — Commentaires ACTIFS d'un élève (non expirés)
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
        .eq('is_archived', false) // ✅ Uniquement actifs
        .or('expires_at.is.null,expires_at.gte.$now'); // ✅ Non expirés

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
  // RÉCUPÉRATION — TOUS les commentaires (pour historique/admin)
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
  // ARCHIVAGE MANUEL d'un commentaire
  // ============================================================
  Future<void> archiveComment(String commentId) async {
    await _supabase.from('comments').update({
      'is_archived': true,
      'archived_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId);
  }

  // ============================================================
  // ARCHIVAGE AUTOMATIQUE des commentaires expirés
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
  // RÉCUPÉRATION ARCHIVE d'un élève
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