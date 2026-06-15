// lib/presentation/pages/parent/widgets/homework_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';

class HomeworkTab extends StatelessWidget {
  final List<Map<String, dynamic>> homeworks;
  final bool isLoading;

  const HomeworkTab({
    super.key,
    required this.homeworks,
    this.isLoading = false,
  });

  Color _getUrgencyColor(String? dueDateStr) {
    if (dueDateStr == null) return Colors.grey;
    final dueDate = DateTime.tryParse(dueDateStr);
    if (dueDate == null) return Colors.grey;
    
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;
    
    if (diff < 0) return Colors.red;
    if (diff <= 1) return Colors.orange;
    if (diff <= 3) return AppTheme.violet;
    return Colors.green;
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'examen': return 'Examen';
      case 'controle': return 'Contrôle';
      case 'interro': return 'Interro';
      case 'devoir': return 'Devoir';
      default: return 'Devoir';
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'examen': return Icons.quiz;
      case 'controle': return Icons.fact_check;
      case 'interro': return Icons.help_outline;
      default: return Icons.assignment;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('EEEE d MMM', 'fr_FR').format(date);
  }

  // ✅ CORRIGÉ : Formate l'heure SQL (HH:MM:SS) → HH:mm
  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (homeworks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucun devoir prévu',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous serez informé dès qu\'un devoir sera programmé',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Grouper par date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final h in homeworks) {
      final date = h['due_date']?.toString().split('T').first ?? 'Sans date';
      grouped.putIfAbsent(date, () => []).add(h);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Sans date') return 1;
        if (b == 'Sans date') return -1;
        return a.compareTo(b);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = grouped[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de date
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.violet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.violet,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${items.length} devoir${items.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            // Liste des devoirs de cette date
            ...items.map((homework) {
              final urgencyColor = _getUrgencyColor(homework['due_date']?.toString());
              final type = homework['type']?.toString();
              // ✅ CORRIGÉ : Utilise due_time au lieu de due_date
              final time = _formatTime(homework['due_time']?.toString());
              
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: urgencyColor.withOpacity(0.3), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getTypeIcon(type),
                              size: 20,
                              color: urgencyColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  homework['title'] ?? 'Devoir',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_getTypeLabel(type)} • ${homework['subjects']?['name'] ?? homework['subject_name'] ?? 'Matière non précisée'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (time.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (homework['room'] != null && homework['room'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.room, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              'Salle : ${homework['room']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                      if (homework['description'] != null && homework['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            homework['description'].toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      // Badge urgence
                      if (urgencyColor == Colors.red || urgencyColor == Colors.orange) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: urgencyColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 12, color: urgencyColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    urgencyColor == Colors.red ? 'En retard' : 'Urgent',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: urgencyColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
