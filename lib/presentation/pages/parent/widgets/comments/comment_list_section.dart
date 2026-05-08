// lib/presentation/pages/parent/widgets/comments/comment_list_section.dart
import 'package:flutter/material.dart';
import '/../../config/theme.dart';
import 'comment_item.dart';

class CommentListSection extends StatelessWidget {
  final List<Map<String, dynamic>> comments;
  final String parentName;
  final Function(String commentId, String? teacherId, String content) onReply;

  const CommentListSection({
    super.key,
    required this.comments,
    required this.parentName,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Aucun message pour le moment',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        return CommentItem(
          comment: comments[index],
          parentName: parentName,
          onReply: onReply,
        );
      },
    );
  }
}