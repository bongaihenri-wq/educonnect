// lib/presentation/pages/teacher/widgets/stat_cards_row.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/theme.dart';

class StatCardsRow extends StatefulWidget {
  final String teacherId;
  final String schoolId;

  const StatCardsRow({
    super.key,
    required this.teacherId,
    required this.schoolId,
  });

  @override
  State<StatCardsRow> createState() => _StatCardsRowState();
}

class _StatCardsRowState extends State<StatCardsRow> {
  bool _isLoading = true;
  int _studentsCount = 0;
  int _classesCount = 0;
  int _coursesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Récupère les classes et matières assignées à cet enseignant
      final schedules = await supabase
          .from('schedules')
          .select('class_id, subject_id')
          .eq('school_id', widget.schoolId)
          .eq('teacher_id', widget.teacherId);

      final uniqueClassIds = schedules.map((s) => s['class_id'] as String).toSet().toList();
      final uniqueSubjectIds = schedules.map((s) => s['subject_id'] as String).toSet().toList();

      // 2. Compte les élèves dans ces classes (sans FetchOptions)
      int studentsCount = 0;
      if (uniqueClassIds.isNotEmpty) {
        final studentsResult = await supabase
            .from('students')
            .select('id')
            .eq('school_id', widget.schoolId)
            .inFilter('class_id', uniqueClassIds);
        
        studentsCount = studentsResult.length;
      }

      setState(() {
        _studentsCount = studentsCount;
        _classesCount = uniqueClassIds.length;
        _coursesCount = uniqueSubjectIds.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erreur stats teacher: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: SizedBox(
              height: 80,
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _StatCard(
              icon: Icons.people,
              value: '$_studentsCount',
              label: 'Élèves',
              color: AppTheme.violet,
            ),
            const SizedBox(width: 12),
            _StatCard(
              icon: Icons.class_,
              value: '$_classesCount',
              label: 'Classes',
              color: AppTheme.teal,
            ),
            const SizedBox(width: 12),
            _StatCard(
              icon: Icons.assignment,
              value: '$_coursesCount',
              label: 'Cours',
              color: AppTheme.sunshine,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bisDark),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.nightBlue,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.nightBlue.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}