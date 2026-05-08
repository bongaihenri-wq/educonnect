// lib/presentation/pages/parent/widgets/comments/comments_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ AJOUTÉ
import 'comment_send_section.dart';
import 'comment_list_section.dart';
import 'reply_dialog.dart';
import '../common_widgets.dart';

class CommentsTab extends StatefulWidget {
  final List<Map<String, dynamic>> comments; // ✅ GARDÉ pour compatibilité
  final String studentId;
  final String parentName;

  const CommentsTab({
    super.key,
    this.comments = const [], // ✅ Optionnel maintenant
    required this.studentId,
    required this.parentName,
  });

  @override
  State<CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<CommentsTab> {
  final _supabase = Supabase.instance.client; // ✅ AJOUTÉ
  List<Map<String, dynamic>> _comments = []; // ✅ AJOUTÉ
  bool _isLoading = true; // ✅ AJOUTÉ

  @override
  void initState() {
    super.initState();
    _loadComments(); // ✅ AJOUTÉ
  }

  // ✅ AJOUTÉ : Chargement dynamique
  Future<void> _loadComments() async {
    if (widget.studentId.isEmpty) {
      setState(() {
        _comments = widget.comments;
        _isLoading = false;
      });
      return;
    }
    try {
      final response = await _supabase
          .from('comments')
          .select('*')
          .eq('student_id', widget.studentId)
          .or('recipient_type.eq.parent,sender_type.eq.parent')
          .order('created_at', ascending: false);
      setState(() {
        _comments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _comments = widget.comments;
        _isLoading = false;
      });
    }
  }

void _showReplyDialog(String commentId, String? teacherId, String content) {
    // ✅ RÉCUPÉRER les infos du commentaire pour le ReplyDialog
    final comment = _comments.firstWhere(
      (c) => c['id'] == commentId,
      orElse: () => {},
    );
    
    final teacherName = comment['sender_name'] as String?;
    final subjectName = comment['target_subject'] as String?;

    showDialog(
      context: context,
      builder: (context) => ReplyDialog(
        commentId: commentId,
        teacherId: teacherId,
        originalContent: content,
        parentName: widget.parentName,
        // ✅ PASSER NOM + MATIÈRE
        teacherName: teacherName,
        subjectName: subjectName,
        onReplySent: () => _loadComments(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator()); // ✅ AJOUTÉ

    // ✅ REMPLACÉ : _comments au lieu de widget.comments
    final parentComments = _comments.where((c) {
      final recipients = c['recipients'];
      if (recipients is List) return recipients.contains('parent');
      if (recipients is String) return recipients.toString().contains('parent');
      return false;
    }).toList();

    // ✅ STRUCTURE IDENTIQUE AU CODE EXISTANT
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentSendSection(
            studentId: widget.studentId,
            parentName: widget.parentName,
            onSent: () => _loadComments(), // ✅ REMPLACÉ : rafraîchir au lieu de setState vide
          ),
          const SizedBox(height: 20),
          CommonWidgets.buildSectionTitle('Messages reçus'),
          const SizedBox(height: 10),
          CommentListSection(
            comments: parentComments,
            parentName: widget.parentName,
            onReply: _showReplyDialog,
          ),
        ],
      ),
    );
  }
}