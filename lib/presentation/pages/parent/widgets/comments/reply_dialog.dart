// lib/presentation/pages/parent/widgets/comments/reply_dialog.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../config/theme.dart'; // ✅ CORRIGÉ : chemin relatif correct

class ReplyDialog extends StatefulWidget { // ✅ CHANGÉ : StatefulWidget
  final String commentId;
  final String? teacherId;
  final String originalContent;
  final String parentName;
  final VoidCallback? onReplySent; // ✅ AJOUTÉ

  const ReplyDialog({
    super.key,
    required this.commentId,
    required this.teacherId,
    required this.originalContent,
    required this.parentName,
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
      
      if (widget.teacherId != null) {
        await supabase.from('notifications').insert({
          'user_id': widget.teacherId,
          'title': 'Réponse d\'un parent',
          'content': '${widget.parentName} a répondu à votre commentaire',
          'type': 'parent_reply',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
          'reference_id': widget.commentId,
        });
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.onReplySent?.call(); // ✅ AJOUTÉ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Réponse envoyée'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Répondre', style: TextStyle(fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Message: "${widget.originalContent}"', // ✅ widget.
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: replyController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Votre réponse...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(fontSize: 12)),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendReply, // ✅ _sendReply
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.violet,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: _isSending // ✅ _isSending
              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Envoyer', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}