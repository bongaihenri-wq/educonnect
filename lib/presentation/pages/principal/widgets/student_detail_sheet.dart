// lib/presentation/pages/principal/widgets/student_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';

class StudentDetailSheet extends StatefulWidget {
  final String studentId;
  final String firstName;
  final String lastName;
  final String matricule;
  final String gender;
  final String className;
  final String schoolId;

  const StudentDetailSheet({
    super.key,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.matricule,
    required this.gender,
    required this.className,
    required this.schoolId,
  });

  @override
  State<StudentDetailSheet> createState() => _StudentDetailSheetState();
}

class _StudentDetailSheetState extends State<StudentDetailSheet> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isFemale = widget.gender == 'f';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: const BoxDecoration(
              color: AppTheme.violet,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0x33FFFFFF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isFemale ? Icons.female : Icons.male,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.lastName.toUpperCase()} ${widget.firstName.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.className} • ${widget.matricule}',
                        style: const TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Assiduité',
                    selected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'Notes',
                    selected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: _selectedTab == 0
                ? _AttendanceTab(studentId: widget.studentId, schoolId: widget.schoolId)
                : _GradesTab(studentId: widget.studentId, schoolId: widget.schoolId),
          ),
          // Bouton Fermer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Fermer', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppTheme.violet : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? AppTheme.violet : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ==================== ASSIDUITÉ AVEC TRIMESTRES CONFIGURABLES ====================
class _AttendanceTab extends StatefulWidget {
  final String studentId;
  final String schoolId;
  const _AttendanceTab({required this.studentId, required this.schoolId});

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  bool _loading = true;
  bool _loadingTrimesters = true;
  Map<String, dynamic> _stats = {};
  String? _error;
  String _period = '30 jours';
  List<Map<String, dynamic>> _trimesters = [];

  @override
  void initState() {
    super.initState();
    _loadTrimesters();
  }

  Future<void> _loadTrimesters() async {
    setState(() => _loadingTrimesters = true);
    try {
      final result = await Supabase.instance.client
          .from('school_trimesters')
          .select('name, start_date, end_date')
          .eq('school_id', widget.schoolId)
          .order('start_date');

      if (mounted) {
        setState(() {
          _trimesters = List<Map<String, dynamic>>.from(result);
          _loadingTrimesters = false;
          // Si des trimestres existent, on prend le premier par défaut
          if (_trimesters.isNotEmpty && _period == '30 jours') {
            _period = _trimesters.first['name'] as String? ?? 'T1';
          }
        });
        _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTrimesters = false;
          _error = e.toString();
        });
      }
    }
  }

  ({String start, String? end}) _getPeriodDates(String period) {
    // Chercher dans les trimestres configurés
    for (final t in _trimesters) {
      if (t['name'] == period) {
        final sd = t['start_date'] as String?;
        final ed = t['end_date'] as String?;
        if (sd != null && ed != null) {
          return (start: sd, end: ed);
        }
      }
    }

    // Fallback : 30 derniers jours
    final thirty = DateTime.now().subtract(const Duration(days: 30));
    return (start: DateFormat('yyyy-MM-dd').format(thirty), end: null);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dates = _getPeriodDates(_period);

      var query = Supabase.instance.client
          .from('attendance')
          .select('status')
          .eq('student_id', widget.studentId)
          .gte('date', dates.start);

      if (dates.end != null) {
        query = query.lte('date', dates.end!);
      }

      final result = await query;

      final items = List<Map<String, dynamic>>.from(result);
      int present = 0, absent = 0, retard = 0;
      for (final i in items) {
        final st = (i['status'] as String? ?? '').toLowerCase();
        if (st == 'present') present++;
        else if (st == 'absent') absent++;
        else if (st == 'retard') retard++;
      }
      final total = items.length;
      final rate = total > 0 ? ((present / total) * 100).toDouble() : 0.0;

      if (mounted) {
        setState(() {
          _stats = {
            'present': present,
            'absent': absent,
            'retard': retard,
            'total': total,
            'rate': rate,
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
    if (_loadingTrimesters) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _trimesters.isEmpty) {
      return Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red)));
    }

    // Construire la liste des options de période
    final periodOptions = [
      '30 jours',
      ..._trimesters.map((t) => t['name'] as String).whereType<String>(),
      'Année',
    ];

    if (_loading) return const Center(child: CircularProgressIndicator());

    final p = _stats['present'] as int? ?? 0;
    final a = _stats['absent'] as int? ?? 0;
    final r = _stats['retard'] as int? ?? 0;
    final t = _stats['total'] as int? ?? 0;
    final rate = _stats['rate'] as double? ?? 0.0;

    final pPct = t > 0 ? ((p / t) * 100).toDouble() : 0.0;
    final aPct = t > 0 ? ((a / t) * 100).toDouble() : 0.0;
    final rPct = t > 0 ? ((r / t) * 100).toDouble() : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur de période dynamique
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: periodOptions.map((pName) {
              final sel = _period == pName;
              return ChoiceChip(
                label: Text(pName),
                selected: sel,
                onSelected: (_) {
                  setState(() => _period = pName);
                  _load();
                },
                selectedColor: AppTheme.violet,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : const Color(0xFF374151),
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: const Color(0xFFE5E7EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Assiduité',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.nightBlue),
          ),
          const SizedBox(height: 16),
          const Text('Répartition', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _LegendDot(color: Colors.green, label: '${pPct.toStringAsFixed(0)}%'),
              const SizedBox(width: 12),
              _LegendDot(color: Colors.red, label: '${aPct.toStringAsFixed(0)}%'),
              const SizedBox(width: 12),
              _LegendDot(color: Colors.orange, label: '${rPct.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 8),
          _AttendanceBar(present: p, absent: a, retard: r, total: t, rate: rate),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatCard(label: 'Présences', value: p, color: Colors.green),
              const SizedBox(width: 8),
              _StatCard(label: 'Absences', value: a, color: Colors.red),
              const SizedBox(width: 8),
              _StatCard(label: 'Retards', value: r, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.show_chart, color: AppTheme.violet, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Taux: ${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.violet),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Total: $t enregistrement${t > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ),
          if (_trimesters.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aucun trimestre configuré. Contactez l\'administrateur.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== NOTES AVEC TRIMESTRE ====================
class _GradesTab extends StatefulWidget {
  final String studentId;
  final String schoolId;
  const _GradesTab({required this.studentId, required this.schoolId});

  @override
  State<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<_GradesTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _subjects = [];
  double _average = 0.0;
  String? _error;
  String _period = 'T1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await Supabase.instance.client
          .from('grades')
          .select('score, max_score, coefficient, subjects(name, code), trimester')
          .eq('student_id', widget.studentId)
          .eq('school_id', widget.schoolId);

      final all = List<Map<String, dynamic>>.from(result);
      final filtered = _period == 'Année'
          ? all
          : all.where((g) => g['trimester'] == _period).toList();

      double tw = 0;
      int tc = 0;
      final map = <String, Map<String, dynamic>>{};
      for (final g in filtered) {
        final score = (g['score'] as num).toDouble();
        final max = (g['max_score'] as num?)?.toDouble() ?? 20.0;
        final coef = (g['coefficient'] as num?)?.toInt() ?? 1;
        final norm = max > 0.0 ? ((score / max) * 20).toDouble() : 0.0;
        tw += norm * coef;
        tc += coef;

        final name = g['subjects']?['name'] as String? ?? 'Inconnu';
        final code = g['subjects']?['code'] as String? ?? name;
        map.putIfAbsent(name, () => {'name': name, 'code': code, 'scores': <double>[]});
        (map[name]!['scores'] as List<double>).add(norm);
      }

      final list = <Map<String, dynamic>>[];
      for (final e in map.entries) {
        final sc = e.value['scores'] as List<double>;
        final avg = sc.isNotEmpty ? (sc.reduce((a, b) => a + b) / sc.length).toDouble() : 0.0;
        e.value['avg'] = avg;
        e.value['count'] = sc.length;
        list.add(e.value);
      }

      if (mounted) {
        setState(() {
          _subjects = list;
          _average = tc > 0 ? (tw / tc).toDouble() : 0.0;
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

  Color _color(double g) => g >= 14 ? Colors.green : g >= 10 ? Colors.orange : Colors.red;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Erreur: $_error'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: ['T1', 'T2', 'T3', 'Année'].map((p) {
              final sel = _period == p;
              return ChoiceChip(
                label: Text(p),
                selected: sel,
                onSelected: (_) {
                  setState(() => _period = p);
                  _load();
                },
                selectedColor: AppTheme.violet,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : const Color(0xFF374151),
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: const Color(0xFFE5E7EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Column(
                children: [
                  const Text('Moyenne Générale', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  Text(
                    _average.toStringAsFixed(2),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _color(_average)),
                  ),
                  const Text('/20', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.bar_chart, size: 18, color: AppTheme.violet),
              const SizedBox(width: 6),
              const Text(
                'Notes par Matière',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.nightBlue),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_subjects.isEmpty)
            const Center(child: Text('Aucune note'))
          else
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _subjects.map((g) {
                  final avg = g['avg'] as double;
                  final color = _color(avg);
                  final h = ((avg / 20) * 120).clamp(4.0, 120.0).toDouble();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(avg.toStringAsFixed(1),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            height: h,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(g['code'] as String? ?? '',
                              style: const TextStyle(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center),
                          Text('(${g['count']})', style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Colors.green, label: '≥14'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.orange, label: '10-14'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.red, label: '<10'),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== WIDGETS COMMUNS ====================
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _AttendanceBar extends StatelessWidget {
  final int present, absent, retard, total;
  final double rate;
  const _AttendanceBar({required this.present, required this.absent, required this.retard, required this.total, required this.rate});

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Container(
        height: 24,
        decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('Aucune donnée', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            if (present > 0)
              Expanded(
                flex: present,
                child: Container(
                  color: Colors.green,
                  child: Center(
                    child: Text('${rate.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            if (absent > 0) Expanded(flex: absent, child: Container(color: Colors.red)),
            if (retard > 0) Expanded(flex: retard, child: Container(color: Colors.orange)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (color == Colors.green) bg = const Color(0xFFDCFCE7);
    else if (color == Colors.red) bg = const Color(0xFFFEE2E2);
    else bg = const Color(0xFFFEF3C7);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color.withAlpha(204))),
          ],
        ),
      ),
    );
  }
}