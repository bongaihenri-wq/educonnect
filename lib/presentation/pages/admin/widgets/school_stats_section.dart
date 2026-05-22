// lib/presentation/pages/admin/widgets/school_stats_section.dart
import 'package:flutter/material.dart';
import '../../../../services/admin_stats_service.dart';
import '../../../../config/theme.dart';
import '../../../widgets/charts/stacked_attendance_bar.dart';
import '../../../widgets/scrollable_list_section.dart';

class SchoolStatsSection extends StatefulWidget {
  final String? schoolId;

  const SchoolStatsSection({super.key, this.schoolId});

  @override
  State<SchoolStatsSection> createState() => _SchoolStatsSectionState();
}

class _SchoolStatsSectionState extends State<SchoolStatsSection> {
  final AdminStatsService _statsService = AdminStatsService();
  List<Map<String, dynamic>> _classAttendance = [];
  List<Map<String, dynamic>> _teacherStats = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void didUpdateWidget(SchoolStatsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schoolId != widget.schoolId && widget.schoolId != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.schoolId == null) return;
    
    setState(() => _loading = true);
    
    try {
      _classAttendance = await _statsService.getAttendanceByClass(widget.schoolId!);
      _teacherStats = await _statsService.getTeachersWithAttendanceStats(widget.schoolId!);
    } catch (e) {
      print('❌ Erreur chargement stats: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === ASSIDUITÉ PAR CLASSE (scrollable) ===
        _buildSectionCard(
          title: 'Assiduité par Classe (30 derniers jours)',
          icon: Icons.bar_chart,
          color: AppTheme.violet,
          child: _loading
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
              : _classAttendance.isEmpty
                  ? _buildEmptyState('Aucune donnée d\'assiduité')
                  : ScrollableListSection(
                      maxHeight: 320, // ~5 barres visibles
                      children: _classAttendance.map((classe) {
                        return StackedAttendanceBar(
                          label: classe['class_name']?.toString() ?? 'Classe',
                          presentPercent: (classe['present_rate_pct'] as num?)?.toDouble() ?? 0.0,
                          absentPercent: (classe['absent_rate_pct'] as num?)?.toDouble() ?? 0.0,
                          latePercent: (classe['late_rate_pct'] as num?)?.toDouble() ?? 0.0,
                        );
                      }).toList(),
                    ),
        ),

        const SizedBox(height: 16),

        // === ASSIDUITÉ PAR ENSEIGNANT (scrollable compact) ===
        _buildSectionCard(
          title: 'Performance Enseignants',
          icon: Icons.people_outline,
          color: Colors.orange,
          child: _loading
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
              : _teacherStats.isEmpty
                  ? _buildEmptyState('Aucun enseignant trouvé')
                  : ScrollableListSection(
                      maxHeight: 260, // ~5 barres compactes
                      isSmall: true,
                      children: _teacherStats.map((teacher) {
                        return StackedAttendanceBar(
                          label: teacher['teacher_name']?.toString() ?? 'Enseignant',
                          presentPercent: (teacher['present_rate_pct'] as num?)?.toDouble() ?? 0.0,
                          absentPercent: (teacher['absent_rate_pct'] as num?)?.toDouble() ?? 0.0,
                          latePercent: (teacher['late_rate_pct'] as num?)?.toDouble() ?? 0.0,
                          isSmall: true,
                        );
                      }).toList(),
                    ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, color: Colors.grey[400], size: 40),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}