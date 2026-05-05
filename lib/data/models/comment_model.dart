// lib/data/models/comment_model.dart

class CommentModel {
  final String id;
  final String studentId;
  final String classId;
  final String teacherId;
  final String schoolId;
  final String content;
  final List<String> recipients;
  final DateTime createdAt;
  final DateTime? expiresAt; // ✅ Date d'effet/expiration
  final bool isArchived;
  final bool isRead;
  final DateTime? readAt;

  CommentModel({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.teacherId,
    required this.schoolId,
    required this.content,
    required this.recipients,
    required this.createdAt,
    this.expiresAt,
    this.isArchived = false,
    this.isRead = false,
    this.readAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      teacherId: json['teacher_id'] as String,
      schoolId: json['school_id'] as String,
      content: json['content'] as String,
      recipients: (json['recipients'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String) 
          : null,
      isArchived: json['is_archived'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'class_id': classId,
      'teacher_id': teacherId,
      'school_id': schoolId,
      'content': content,
      'recipients': recipients,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_archived': isArchived,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
    };
  }

  // ✅ Helper : Est-ce que le commentaire est actif ?
  bool get isActive {
    if (isArchived) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  // ✅ Helper : Jours restants avant expiration
  int? get daysRemaining {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now()).inDays;
  }
}