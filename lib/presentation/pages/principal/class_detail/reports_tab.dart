// lib/presentation/pages/principal/class_detail/reports_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import 'widgets/common_widgets.dart';

class ReportsTab extends StatefulWidget {
  final String classId;
  final String schoolId;
  const ReportsTab(
      {super.key,
      required this.classId,
      required this.schoolId,
      required List<Map<String, dynamic>> periods});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stRes = await Supabase.instance.client
          .from('students')
          .select('id')
          .eq('class_id', widget.classId);
      final students = List<Map<String, dynamic>>.from(stRes);
      final ids = students.map((s) => s['id'] as String).toList();
      final total = students.length;

      final grRes = await Supabase.instance.client
          .from('grades')
          .select('score, max_score, coefficient, student_id')
          .eq('school_id', widget.schoolId);
      final allG = List<Map<String, dynamic>>.from(grRes);
      final cg = allG.where((g) => ids.contains(g['student_id'])).toList();

      double tw = 0;
      int tc = 0;
      int b8 = 0, b810 = 0, a10 = 0;
      for (final sid in ids) {
        final sg = cg.where((g) => g['student_id'] == sid).toList();
        double sw = 0;
        int sc = 0;
        for (final g in sg) {
          final score = (g['score'] as num).toDouble();
          final max = (g['max_score'] as num?)?.toDouble() ?? 20.0;
          final coef = (g['coefficient'] as num?)?.toInt() ?? 1;
          final norm = max > 0.0 ? ((score / max) * 20).toDouble() : 0.0;
          sw += norm * coef;
          sc += coef;
        }
        final avg = sc > 0 ? (sw / sc).toDouble() : 0.0;
        tw += avg;
        tc++;
        if (avg < 8)
          b8++;
        else if (avg < 10)
          b810++;
        else
          a10++;
      }

      final thirty = DateTime.now().subtract(const Duration(days: 30));
      final attRes = await Supabase.instance.client
          .from('attendance')
          .select('status, student_id')
          .eq('school_id', widget.schoolId)
          .gte('date', DateFormat('yyyy-MM-dd').format(thirty));
      final allA = List<Map<String, dynamic>>.from(attRes);
      final ca = allA.where((a) => ids.contains(a['student_id'])).toList();
      int pr = 0, ab = 0, re = 0;
      for (final a in ca) {
        final st = a['status'] as String? ?? '';
        if (st == 'present')
          pr++;
        else if (st == 'absent')
          ab++;
        else if (st == 'retard') re++;
      }

      if (mounted) {
        setState(() {
          _stats = {
            'total': total,
            'class_avg': tc > 0 ? (tw / tc).toDouble() : 0.0,
            'below_8': b8,
            'between_8_10': b810,
            'above_10': a10,
            'success_rate': total > 0 ? ((a10 / total) * 100).toDouble() : 0.0,
            'attendance': {
              'present': pr,
              'absent': ab,
              'retard': re,
              'total': ca.length
            },
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return buildError(_error!);
    if (_stats.isEmpty) return buildEmpty('Aucune donnée');

    final t = _stats['total'] as int? ?? 0;
    final avg = _stats['class_avg'] as double? ?? 0.0;
    final b8 = _stats['below_8'] as int? ?? 0;
    final b810 = _stats['between_8_10'] as int? ?? 0;
    final a10 = _stats['above_10'] as int? ?? 0;
    final sr = _stats['success_rate'] as double? ?? 0.0;
    final att = _stats['attendance'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatCard(
              title: 'Élèves',
              value: t.toString(),
              icon: Icons.people,
              color: Colors.blue),
          const SizedBox(height: 12),
          StatCard(
              title: 'Moyenne classe',
              value: avg.toStringAsFixed(2),
              icon: Icons.school,
              color: AppTheme.violet),
          const SizedBox(height: 12),
          StatCard(
              title: 'Taux réussite',
              value: '${sr.toStringAsFixed(1)}%',
              icon: Icons.check_circle,
              color: Colors.green),
          const SizedBox(height: 24),
          const Text('Répartition des moyennes',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.nightBlue)),
          const SizedBox(height: 12),
          DistributionBar(b8: b8, b810: b810, a10: a10, total: t),
          const SizedBox(height: 24),
          const Text('Présences (30 jours)',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.nightBlue)),
          const SizedBox(height: 12),
          AttSummary(att: att),
        ],
      ),
    );
  }
}
