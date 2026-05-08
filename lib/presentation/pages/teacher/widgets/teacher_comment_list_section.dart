// lib/presentation/pages/teacher/widgets/teacher_comment_list_section.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/theme.dart';

class TeacherCommentListSection extends StatefulWidget {
  final String teacherId;

  const TeacherCommentListSection({
    super.key,
    required this.teacherId,
  });

  @override
  State<TeacherCommentListSection> createState() => _TeacherCommentListSectionState();
}

class _TeacherCommentListSectionState extends State<TeacherCommentListSection> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    if (widget.teacherId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // ✅ Récupère les messages destinés à cet enseignant
      final response = await _supabase
          .from('comments')
          .select('*, students(first_name, last_name)')
          .eq('teacher_id', widget.teacherId)
          .eq('recipient_type', 'teacher')
          .order('created_at', ascending: false);

      setState(() {
        _comments = List<Map<String, dynamic>>.from(response);
        _unreadCount = _comments.where((c) => !(c['is_read'] as bool? ?? true)).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erreur chargement messages: $e');
    }
  }

  Future<void> _markAsRead(String commentId) async {
    try {
      await _supabase
          .from('comments')
          .update({'is_read': true})
          .eq('id', commentId);
      
      setState(() {
        final index = _comments.indexWhere((c) => c['id'] == commentId);
        if (index != -1) {
          _comments[index]['is_read'] = true;
          _unreadCount = _comments.where((c) => !(c['is_read'] as bool? ?? true)).length;
        }
      });
    } catch (e) {
      debugPrint('Erreur marquage lu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.message, color: AppTheme.violet, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Messages des parents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.nightBlue,
                  ),
                ),
                if (_unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_comments.isEmpty)
              _buildEmptyState()
            else
              ..._comments.map((comment) => _buildCommentCard(comment)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'Aucun message',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final isRead = comment['is_read'] as bool? ?? true;
    final student = comment['students'] as Map<String, dynamic>?;
    final studentName = student != null 
        ? '${student['first_name']} ${student['last_name']}'
        : 'Élève inconnu';
    final content = comment['content'] as String? ?? 'Aucun contenu';
    final senderName = comment['sender_name'] as String? ?? 'Parent';
    final createdAt = DateTime.parse(comment['created_at'] as String);
    final hasReply = comment['parent_reply'] != null && (comment['parent_reply'] as String).isNotEmpty;

    return InkWell(
      onTap: () {
        if (!isRead) _markAsRead(comment['id'] as String);
        _showMessageDetail(comment, studentName);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppTheme.violet.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : AppTheme.violet.withOpacity(0.3),
            width: isRead ? 1 : 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.nightBlue,
                        ),
                      ),
                      Text(
                        'Pour: $studentName',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.nightBlue.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                if (hasReply)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Répondu',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDetail(Map<String, dynamic> comment, String studentName) {
    final content = comment['content'] as String? ?? '';
    final reply = comment['parent_reply'] as String?;
    final createdAt = DateTime.parse(comment['created_at'] as String);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.message, color: AppTheme.violet, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Message de $studentName',
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.violet.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
              ),
              child: Text(content, style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 12),
            Text(
              'Envoyé le ${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            if (reply != null && reply.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.reply, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Réponse du parent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Text(reply, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}