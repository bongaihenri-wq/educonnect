// lib/presentation/pages/parent/widgets/messages/unified_messages_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../services/parent_message_service.dart';
import 'unified_message_item.dart';
import '../comments/comment_send_section.dart';
import '../comments/reply_dialog.dart';
import '../common_widgets.dart';

class UnifiedMessagesTab extends StatefulWidget {
  final String studentId;
  final String parentName;
  final String schoolId;
  final String? classId;

  const UnifiedMessagesTab({
    super.key,
    required this.studentId,
    required this.parentName,
    required this.schoolId,
    this.classId,
  });

  @override
  State<UnifiedMessagesTab> createState() => _UnifiedMessagesTabState();
}

class _UnifiedMessagesTabState extends State<UnifiedMessagesTab> {
  final _service = ParentMessageService();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _service.getParentMessages(
        studentId: widget.studentId,
        schoolId: widget.schoolId,
        classId: widget.classId,
      );
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showReplyDialog(String messageId, String? teacherId, String content, String type) {
    if (type != 'comment') return; // Pas de réponse pour devoirs/admin

    final message = _messages.firstWhere(
      (m) => m['message_id'] == messageId,
      orElse: () => {},
    );
    
    final teacherName = message['sender_name'] as String?;
    final subjectName = message['target_subject'] as String?;

    showDialog(
      context: context,
      builder: (context) => ReplyDialog(
        commentId: messageId.replaceFirst('hw_', '').replaceFirst('adm_', ''),
        teacherId: teacherId,
        originalContent: content,
        parentName: widget.parentName,
        teacherName: teacherName,
        subjectName: subjectName,
        onReplySent: () => _loadMessages(),
      ),
    );
  }

  Future<void> _markAsRead(String messageId, String type) async {
    await _service.markAsRead(messageId, type);
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section envoi message (parent → enseignant/admin)
          CommentSendSection(
            studentId: widget.studentId,
            parentName: widget.parentName,
            onSent: () => _loadMessages(),
          ),
          const SizedBox(height: 20),
          
          CommonWidgets.buildSectionTitle('Messages & Devoirs'),
          const SizedBox(height: 10),
          
          // Liste unifiée
          _messages.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun message ou devoir',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => UnifiedMessageItem(
                    message: _messages[index],
                    parentName: widget.parentName,
                    onReply: _showReplyDialog,
                    onMarkRead: _markAsRead,
                  ),
                ),
        ],
      ),
    );
  }
}
