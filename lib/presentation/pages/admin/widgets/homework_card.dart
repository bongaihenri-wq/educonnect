// lib/presentation/pages/admin/widgets/homework_card.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class HomeworkCard extends StatelessWidget {
  final Map<String, dynamic> homework;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HomeworkCard({
    super.key,
    required this.homework,
    required this.onTap,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = homework['title'] ?? 'Sans titre';
    final type = homework['type'] ?? 'devoir';
    final status = homework['status'] ?? 'prevu';
    final priority = homework['priority'] ?? 'normale';
    final dueDate = homework['due_date']?.toString() ?? '';
    final subjectName = homework['subjects']?['name'] ?? '';
    final teacherName = homework['app_users']?['first_name'] ?? '';
    final className = homework['classes']?['name'] ?? '';
    final room = homework['room'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne 1: Type + Priorité + Menu
              Row(
                children: [
                  _buildMiniChip(_getTypeLabel(type), _getTypeColor(type)),
                  const SizedBox(width: 6),
                  if (priority == 'urgente')
                    _buildMiniChip('URG', Colors.red, isUrgent: true),
                  const Spacer(),
                  _buildStatusChip(status),
                  const SizedBox(width: 4),
                  _buildPopupMenu(status),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Titre compact
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 6),
              
              // Ligne info: Date + Salle
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: _isOverdue(dueDate, status) ? Colors.red : Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateShort(dueDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: _isOverdue(dueDate, status) ? Colors.red : Colors.grey[600],
                      fontWeight: _isOverdue(dueDate, status) ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (room.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.room, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(room, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ],
              ),
              
              const SizedBox(height: 6),
              
              // Tags compactes
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (subjectName.isNotEmpty)
                    _buildTinyTag(Icons.book, subjectName, Colors.blue),
                  if (teacherName.isNotEmpty)
                    _buildTinyTag(Icons.person, teacherName, Colors.purple),
                  if (className.isNotEmpty)
                    _buildTinyTag(Icons.class_, className, Colors.teal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, Color color, {bool isUrgent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: isUrgent ? Border.all(color: color, width: 1) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            _getStatusLabelShort(status),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withOpacity(0.7)),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(String status) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 18),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        switch (value) {
          case 'complete': onToggleComplete(); break;
          case 'edit': onEdit(); break;
          case 'delete': onDelete(); break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'complete',
          height: 36,
          child: Row(
            children: [
              Icon(status == 'acheve' ? Icons.undo : Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text(status == 'acheve' ? 'Non achevé' : 'Achevé', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 16),
              SizedBox(width: 6),
              Text('Modifier', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 16),
              SizedBox(width: 6),
              Text('Supprimer', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateShort(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return dateStr;
    }
  }

  bool _isOverdue(String dueDate, String status) {
    if (status == 'acheve' || status == 'annule') return false;
    try {
      final date = DateTime.parse(dueDate);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'examen': return 'Ex';
      case 'controle': return 'Ctrl';
      case 'interro': return 'Int';
      case 'devoir': default: return 'Dev';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'examen': return Colors.red;
      case 'controle': return Colors.orange;
      case 'interro': return Colors.blue;
      case 'devoir': default: return Colors.green;
    }
  }

  String _getStatusLabelShort(String status) {
    switch (status) {
      case 'acheve': return 'Fait';
      case 'en_cours': return 'En cours';
      case 'annule': return 'Annulé';
      case 'prevu': default: return 'Prévu';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'acheve': return Colors.green;
      case 'en_cours': return Colors.blue;
      case 'annule': return Colors.grey;
      case 'prevu': default: return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'acheve': return Icons.check_circle;
      case 'en_cours': return Icons.play_circle;
      case 'annule': return Icons.cancel;
      case 'prevu': default: return Icons.schedule;
    }
  }
}