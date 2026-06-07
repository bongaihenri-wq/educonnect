// lib/presentation/pages/admin/widgets/homeworks/homework_detail_dialog.dart
import 'package:flutter/material.dart';

class HomeworkDetailDialog extends StatelessWidget {
  final Map<String, dynamic> homework;

  const HomeworkDetailDialog({
    super.key,
    required this.homework,
  });

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'examen': return 'Examen';
      case 'controle': return 'Contrôle';
      case 'interro': return 'Interro';
      case 'devoir': default: return 'Devoir';
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'acheve': return 'Achevé';
      case 'en_cours': return 'En cours';
      case 'annule': return 'Annulé';
      case 'prevu': default: return 'Prévu';
    }
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(homework['title'] ?? 'Détail'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', _getTypeLabel(homework['type'])),
            _buildDetailRow('Statut', _getStatusLabel(homework['status'])),
            _buildDetailRow('Priorité', homework['priority'] ?? '-'),
            _buildDetailRow('Date', homework['due_date'] ?? '-'),
            _buildDetailRow('Classe', homework['classes']?['name'] ?? '-'),
            _buildDetailRow('Matière', homework['subjects']?['name'] ?? '-'),
            if (homework['room'] != null && homework['room'].toString().isNotEmpty)
              _buildDetailRow('Salle', homework['room']),
            _buildDetailRow('Description', homework['description'] ?? '-'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}