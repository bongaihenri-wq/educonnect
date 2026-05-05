// lib/presentation/pages/teacher/widgets/comment_list_section.dart
import 'package:educonnect/data/models/comment_model.dart';
import 'package:educonnect/data/repositories/comment_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/theme.dart';

class CommentListSection extends StatefulWidget {
  final String studentId;
  final String? schoolId;

  const CommentListSection({
    super.key,
    required this.studentId,
    this.schoolId,
  });

  @override
  State<CommentListSection> createState() => _CommentListSectionState();
}

class _CommentListSectionState extends State<CommentListSection> {
  late Future<List<CommentModel>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() {
    final repo = CommentRepository(Supabase.instance.client);
    // ✅ CORRIGÉ : Utiliser getStudentActiveComments (nouvelle méthode)
    _commentsFuture = repo.getStudentActiveComments(
      widget.studentId,
      schoolId: widget.schoolId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CommentModel>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            )),
          );
        }

        final comments = snapshot.data ?? [];

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commentaires (${comments.length})',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Aucun commentaire actif pour cet élève',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              else
                ...comments.map((comment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CommentCard(
                    from: 'Enseignant',
                    to: comment.recipients.join(', '),
                    message: comment.content,
                    time: _formatTime(comment.createdAt),
                    // ✅ AJOUTÉ : Afficher la date d'expiration si présente
                    expiresAt: comment.expiresAt,
                    isIncoming: true,
                    isSystem: false,
                    isRead: comment.isRead,
                  ),
                )),
            ]),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${date.day}/${date.month}';
  }
}

class _CommentCard extends StatelessWidget {
  final String from, to, message, time;
  final DateTime? expiresAt; // ✅ AJOUTÉ
  final bool isIncoming, isSystem, isRead;

  const _CommentCard({
    required this.from,
    required this.to,
    required this.message,
    required this.time,
    this.expiresAt, // ✅ AJOUTÉ
    required this.isIncoming,
    this.isSystem = false,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSystem ? AppTheme.violetPale : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isRead ? AppTheme.bisDark : const Color(0xFF7C3AED)),
        boxShadow: isRead ? null : [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isSystem ? Icons.campaign : Icons.person,
              size: 16,
              color: isSystem ? AppTheme.violet : const Color(0xFF7C3AED),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                from,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                to,
                style: const TextStyle(fontSize: 10, color: Color(0xFF7C3AED)),
              ),
            ),
            const SizedBox(width: 8),
            Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 14)),
          
          // ✅ AJOUTÉ : Afficher la date d'expiration si présente
          if (expiresAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Valable jusqu\'au ${expiresAt!.day.toString().padLeft(2, '0')}/${expiresAt!.month.toString().padLeft(2, '0')}/${expiresAt!.year}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}