import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class CommentListSection extends StatelessWidget {
  const CommentListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Commentaires', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('Nouveau')),
              ],
            ),
          ),
          const _CommentCard(from: 'M. Martin (Parent)', to: '6ème A', message: 'Emma sera absente demain.', time: '2h', isIncoming: true),
          const SizedBox(height: 12),
          const _CommentCard(from: 'Administration', to: 'Tous', message: 'Réunion vendredi à 16h.', time: '2j', isIncoming: true, isSystem: true),
        ]),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final String from, to, message, time;
  final bool isIncoming, isSystem;

  const _CommentCard({required this.from, required this.to, required this.message, required this.time, required this.isIncoming, this.isSystem = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSystem ? AppTheme.violetPale : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bisDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(isSystem ? Icons.campaign : Icons.person, size: 16, color: isSystem ? AppTheme.violet : Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(from, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
