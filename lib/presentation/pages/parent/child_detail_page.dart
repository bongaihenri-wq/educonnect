// lib/presentation/pages/parent/child_detail_page.dart
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ChildDetailPage extends StatelessWidget {
  final Map<String, dynamic> childData;
  final Map<String, dynamic> parentData;
  final String relationship;

  const ChildDetailPage({
    super.key,
    required this.childData,
    required this.parentData,
    required this.relationship,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${childData['first_name']} ${childData['last_name']}';
    final className = childData['classes']?['name'] ?? 'Classe inconnue';
    final matricule = childData['matricule'];

    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header avec retour
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      color: AppTheme.nightBlue,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            // Info enfant
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.violetGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          '${childData['first_name'][0]}${childData['last_name'][0]}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.violet,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nom
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Classe & Matricule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                    ),
                      child: Text(
                        '$className • Matricule: $matricule',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Onglets: Semaine | Jour
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.bisDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.violet,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Semaine',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Aujourd\'hui',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.nightBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Vue semaine détaillée
            SliverToBoxAdapter(
              child: _buildWeeklyView(),
            ),

            // Stats résumé
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résumé de la semaine',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.nightBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Présent', '8', AppTheme.success, '🟢'),
                        _buildStatItem('Absent', '1', AppTheme.rose, '🔴'),
                        _buildStatItem('Retard', '1', AppTheme.warning, '🟠'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lundi 10 Avril',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.nightBlue,
            ),
          ),
          const SizedBox(height: 16),
          
          // Cours du jour
          _buildCourseRow(
            subject: 'Mathématiques',
            time: '08h00 - 10h00',
            status: 'present',
            room: 'Salle 12',
          ),
          const Divider(),
          _buildCourseRow(
            subject: 'Histoire-Géographie',
            time: '10h00 - 11h30',
            status: 'present',
            room: 'Salle 8',
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Mardi 11 Avril',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.nightBlue,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildCourseRow(
            subject: 'Sciences',
            time: '08h00 - 10h00',
            status: 'present',
            room: 'Labo 3',
          ),
          const Divider(),
          _buildCourseRow(
            subject: 'Physique-Chimie',
            time: '10h00 - 11h30',
            status: 'absent',
            room: 'Labo 1',
            note: 'Absence non justifiée',
          ),
        ],
      ),
    );
  }

  Widget _buildCourseRow({
    required String subject,
    required String time,
    required String status,
    required String room,
    String? note,
  }) {
    final statusColor = _getStatusColor(status);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Point status
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withOpacity(0.3), width: 4),
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.nightBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppTheme.nightBlueLight),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.nightBlueLight.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.meeting_room, size: 14, color: AppTheme.nightBlueLight),
                    const SizedBox(width: 4),
                    Text(
                      room,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.nightBlueLight.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Badge status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusLabel(status),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.nightBlueLight.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return AppTheme.success;
      case 'absent':
        return AppTheme.rose;
      case 'late':
        return AppTheme.warning;
      default:
        return AppTheme.bisDark;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'present':
        return 'Présent';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'Retard';
      default:
        return '-';
    }
  }
}