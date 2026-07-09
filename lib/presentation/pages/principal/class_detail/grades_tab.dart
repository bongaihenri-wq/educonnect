// lib/presentation/pages/principal/class_detail/grades_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../services/period_service.dart';
import '../../admin/widgets/period_selector.dart';
import 'widgets/common_widgets.dart';

class GradesTab extends StatefulWidget {
  final String classId;
  final String schoolId;
  final List<Map<String, dynamic>> periods;

  const GradesTab({
    super.key,
    required this.classId,
    required this.schoolId,
    required this.periods,
  });

  @override
  State<GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<GradesTab> {
  final _periodService = PeriodService();
  bool _loading = true;
  Map<String, dynamic>? _selectedPeriod;
  List<Map<String, dynamic>> _students = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.periods.isNotEmpty) {
      _selectedPeriod = widget.periods.firstWhere(
        (p) => p['is_active'] == true,
        orElse: () => widget.periods.last,
      );
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      DateTime? startDate;
      DateTime? endDate;

      if (_selectedPeriod != null &&
          !_periodService.isDynamicPeriod(_selectedPeriod!)) {
        final sd = _selectedPeriod!['start_date'] as String?;
        final ed = _selectedPeriod!['end_date'] as String?;
        if (sd != null) startDate = DateTime.tryParse(sd);
        if (ed != null) endDate = DateTime.tryParse(ed);
      }

      final stRes = await Supabase.instance.client
          .from('students')
          .select('id, first_name, last_name')
          .eq('class_id', widget.classId);
      final students = List<Map<String, dynamic>>.from(stRes);
      final ids = students.map((s) => s['id'] as String).toList();

      var query = Supabase.instance.client
          .from('grades')
          .select(
              'score, max_score, coefficient, student_id, subjects(name), date')
          .eq('school_id', widget.schoolId);

      if (startDate != null) {
        query = query.gte('date', DateFormat('yyyy-MM-dd').format(startDate));
      }
      if (endDate != null) {
        query = query.lte('date', DateFormat('yyyy-MM-dd').format(endDate));
      }

      final grRes = await query;
      final allGrades = List<Map<String, dynamic>>.from(grRes);

      final result = <Map<String, dynamic>>[];
      for (final st in students) {
        final sid = st['id'] as String;
        final sg = allGrades.where((g) => g['student_id'] == sid).toList();
        double tw = 0;
        int tc = 0;
        final subs = <String>{};
        for (final g in sg) {
          final score = (g['score'] as num).toDouble();
          final max = (g['max_score'] as num?)?.toDouble() ?? 20.0;
          final coef = (g['coefficient'] as num?)?.toInt() ?? 1;
          final norm = max > 0.0 ? ((score / max) * 20).toDouble() : 0.0;
          tw += norm * coef;
          tc += coef;
          subs.add(g['subjects']?['name'] as String? ?? 'Inconnu');
        }
        final avg = tc > 0 ? (tw / tc).toDouble() : 0.0;
        result.add({
          'name': '${st['first_name']} ${st['last_name']}',
          'average': avg,
          'grades_count': sg.length,
          'subjects_count': subs.length,
        });
      }
      result.sort(
          (a, b) => (b['average'] as double).compareTo(a['average'] as double));

      if (mounted) {
        setState(() {
          _students = result;
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

  Color _color(double avg) => avg >= 14
      ? Colors.green
      : avg >= 10
          ? Colors.orange
          : Colors.red;

  @override
  Widget build(BuildContext context) {
    if (widget.periods.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucune période définie pour cette école.\nContactez l\'administrateur.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        PeriodSelector(
          periods: widget.periods,
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: (period) {
            setState(() => _selectedPeriod = period);
            _load();
          },
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? buildError(_error!)
                  : _students.isEmpty
                      ? buildEmpty('Aucune note')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: _students.length,
                          itemBuilder: (ctx, i) {
                            final s = _students[i];
                            final avg = s['average'] as double;
                            final color = _color(avg);
                            final name = s['name'] as String;

                            Color bg;
                            if (color == Colors.green)
                              bg = const Color(0xFFDCFCE7);
                            else if (color == Colors.orange)
                              bg = const Color(0xFFFEF3C7);
                            else
                              bg = const Color(0xFFFEE2E2);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                          color: bg, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text(
                                          avg.toStringAsFixed(1),
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: color),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${s['grades_count']} note(s) • ${s['subjects_count']} matière(s)',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: bg,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(
                                        avg >= 10 ? 'Validé' : 'À risque',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: color,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
