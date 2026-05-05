// lib/presentation/pages/parent/widgets/summary_tab.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'common_widgets.dart';

class SummaryTab extends StatefulWidget {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> attendance;
  final List<Map<String, dynamic>> timetable;
  final String studentId;

  const SummaryTab({
    super.key,
    required this.stats,
    required this.attendance,
    required this.timetable,
    required this.studentId,
  });

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  Map<String, dynamic>? _nextClass;
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // TODO: Injecter ChildDetailService via le constructeur ou Provider
    // Pour l'instant, simulé - remplacer par vrai appel
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── STATS ─────────────────────────
          Row(
            children: [
              CommonWidgets.buildStatCard(
                'Présences\n30 jours',
                '${widget.stats['present'] ?? 0}',
                Colors.green,
                Icons.check_circle,
              ),
              const SizedBox(width: 12),
              CommonWidgets.buildStatCard(
                'Absences\n30 jours',
                '${widget.stats['absent'] ?? 0}',
                Colors.red,
                Icons.cancel,
              ),
              const SizedBox(width: 12),
              CommonWidgets.buildStatCard(
                'Moyenne\nGénérale',
                widget.stats['average'] != null && (widget.stats['average'] as double) > 0
                    ? '${(widget.stats['average'] as double).toStringAsFixed(1)}/20'
                    : '-/20',
                AppTheme.violet,
                Icons.grade,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // ─── PROCHAIN COURS ────────────────
          CommonWidgets.buildSectionTitle('Prochain cours'),
          const SizedBox(height: 12),
          _buildNextClass(),
          
          const SizedBox(height: 24),
          
          // ─── ALERTES 24H ─────────────────
          CommonWidgets.buildSectionTitle('Dernières alertes'),
          const SizedBox(height: 12),
          _buildRecentAlerts(),
        ],
      ),
    );
  }

  Widget _buildNextClass() {
    if (_nextClass == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_busy, color: Colors.grey),
            SizedBox(width: 12),
            Text(
              'Aucun cours prévu',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.violet.withOpacity(0.1), AppTheme.violet.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.violet.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.violet.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.schedule, color: AppTheme.violet),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nextClass!['subject'] ?? 'Cours',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.nightBlue,
                  ),
                ),
                Text(
                  '${_nextClass!['start_time']} - ${_nextClass!['end_time']} • ${_nextClass!['room']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.nightBlueLight.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts() {
    if (_alerts.isEmpty) {
      return CommonWidgets.buildEmptyState('Aucune alerte récente');
    }

    return Column(
      children: _alerts.map((a) => _buildAlertItem(a)).toList(),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final color = alert['color'] as Color;
    final icon = alert['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['message'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.nightBlue,
                  ),
                ),
                Text(
                  alert['time'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.nightBlueLight.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}