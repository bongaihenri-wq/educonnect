// lib/presentation/pages/parent/widgets/comments/reply_dialog.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../config/theme.dart';

class ReplyDialog extends StatefulWidget {
  final String commentId;
  final String? teacherId;
  final String originalContent;
  final String parentName;
  final String? teacherName; // ✅ AJOUTÉ : nom de l'enseignant pour l'affichage
  final String? subjectName;  // ✅ AJOUTÉ : matière pour l'affichage
  final VoidCallback? onReplySent;

  const ReplyDialog({
    super.key,
    required this.commentId,
    required this.teacherId,
    required this.originalContent,
    required this.parentName,
    this.teacherName,
    this.subjectName,
    this.onReplySent,
  });

  @override
  State<ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<ReplyDialog> {
  final replyController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isSending = false;

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (replyController.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    try {
      await supabase.from('comments').update({
        'parent_reply': replyController.text.trim(),
        'replied_at': DateTime.now().toIso8601String(),
        'is_read': false,
      }).eq('id', widget.commentId);
      
      // ✅ NOTIFICATION À L'ENSEIGNANT SPÉCIFIQUE
      if (widget.teacherId != null) {
        await supabase.from('notifications').insert({
          'user_id': widget.teacherId,
          'title': 'Réponse de ${widget.parentName}',
          'content': widget.subjectName != null 
              ? '${widget.parentName} a répondu à votre message (${widget.subjectName})'
              : '${widget.parentName} a répondu à votre message',
          'type': 'comment', // ✅ Utiliser 'message' au lieu de 'parent_reply' pour éviter contrainte
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
          'reference_id': widget.commentId,
        });
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.onReplySent?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Réponse envoyée'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.reply, color: AppTheme.violet, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Répondre ${widget.teacherName != null ? 'à ${widget.teacherName}' : ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.violet.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message original ${widget.subjectName != null ? '(${widget.subjectName})' : ''}',
                  style: TextStyle(fontSize: 10, color: AppTheme.violet, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${widget.originalContent}"',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: replyController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Votre réponse...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.violet),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: Text('Annuler', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendReply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.violet,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Envoyer', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}