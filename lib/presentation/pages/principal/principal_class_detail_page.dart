// lib/presentation/pages/principal/principal_class_detail_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import 'widgets/student_detail_sheet.dart';

class PrincipalClassDetailPage extends StatefulWidget {
  final String classId;
  final String className;
  final String schoolId;

  const PrincipalClassDetailPage({super.key, required this.classId, required this.className, required this.schoolId});

  @override
  State<PrincipalClassDetailPage> createState() => _PrincipalClassDetailPageState();
}

class _PrincipalClassDetailPageState extends State<PrincipalClassDetailPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.bisLight,
        appBar: AppBar(
          title: Text(widget.className, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: AppTheme.violet,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Élèves'),
              Tab(icon: Icon(Icons.school), text: 'Notes'),
              Tab(icon: Icon(Icons.fact_check), text: 'Appels'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Rapports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StudentsTab(classId: widget.classId, schoolId: widget.schoolId, className: widget.className),
            _GradesTab(classId: widget.classId, schoolId: widget.schoolId),
            _AttendanceTab(classId: widget.classId, schoolId: widget.schoolId),
            _ReportsTab(classId: widget.classId, schoolId: widget.schoolId),
          ],
        ),
      ),
    );
  }
}

// ==================== ONGLET ÉLÈVES ====================
class _StudentsTab extends StatefulWidget {
  final String classId;
  final String schoolId;
  final String className;
  const _StudentsTab({required this.classId, required this.schoolId, required this.className});

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _students = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await Supabase.instance.client
          .from('students')
          .select('id, first_name, last_name, matricule, gender')
          .eq('class_id', widget.classId)
          .order('last_name');
      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(result);
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

  void _showDetail(Map<String, dynamic> s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: StudentDetailSheet(
          studentId: s['id'] as String? ?? '',
          firstName: s['first_name'] as String? ?? '',
          lastName: s['last_name'] as String? ?? '',
          matricule: s['matricule'] as String? ?? '',
          gender: (s['gender'] as String? ?? '').toString().toLowerCase(),
          className: widget.className,
          schoolId: widget.schoolId,
        ),
      ),
    );
  }

  Future<void> _remove(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer de la classe'),
        content: const Text('Retirer cet élève de cette classe ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retirer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.from('students').update({'class_id': null}).eq('id', id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError(_error!);
    if (_students.isEmpty) return _buildEmpty('Aucun élève');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _students.length,
      itemBuilder: (ctx, i) {
        final s = _students[i];
        final fn = s['first_name'] as String? ?? '';
        final ln = s['last_name'] as String? ?? '';
        final mat = s['matricule'] as String? ?? '—';
        final g = (s['gender'] as String? ?? '').toString().toLowerCase();
        final isF = g == 'f';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isF ? const Color(0xFFFCE7F3) : const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(isF ? Icons.female : Icons.male, color: isF ? const Color(0xFFEC4899) : const Color(0xFF3B82F6), size: 20)),
            ),
            title: Text(
              '${ln.toUpperCase()} ${fn.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('Matricule: $mat', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.visibility, size: 20, color: Color(0xFF9CA3AF)), onPressed: () => _showDetail(s), visualDensity: VisualDensity.compact),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _remove(s['id']), visualDensity: VisualDensity.compact),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== ONGLET NOTES ====================
class _GradesTab extends StatefulWidget {
  final String classId;
  final String schoolId;
  const _GradesTab({required this.classId, required this.schoolId});

  @override
  State<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<_GradesTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _students = [];
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
          .select('id, first_name, last_name')
          .eq('class_id', widget.classId);
      final students = List<Map<String, dynamic>>.from(stRes);
      final ids = students.map((s) => s['id'] as String).toList();

      final grRes = await Supabase.instance.client
          .from('grades')
          .select('score, max_score, coefficient, student_id, subjects(name)')
          .eq('school_id', widget.schoolId);
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
      result.sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));

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

  Color _color(double avg) => avg >= 14 ? Colors.green : avg >= 10 ? Colors.orange : Colors.red;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError(_error!);
    if (_students.isEmpty) return _buildEmpty('Aucune note');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _students.length,
      itemBuilder: (ctx, i) {
        final s = _students[i];
        final avg = s['average'] as double;
        final color = _color(avg);
        final name = s['name'] as String;

        Color bg;
        if (color == Colors.green) bg = const Color(0xFFDCFCE7);
        else if (color == Colors.orange) bg = const Color(0xFFFEF3C7);
        else bg = const Color(0xFFFEE2E2);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      avg.toStringAsFixed(1),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${s['grades_count']} note(s) • ${s['subjects_count']} matière(s)',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    avg >= 10 ? 'Validé' : 'À risque',
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== ONGLET APPELS ====================
class _AttendanceTab extends StatefulWidget {
  final String classId;
  final String schoolId;
  const _AttendanceTab({required this.classId, required this.schoolId});

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
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
          .select('id, first_name, last_name')
          .eq('class_id', widget.classId);
      final students = List<Map<String, dynamic>>.from(stRes);
      final ids = students.map((s) => s['id'] as String).toList();
      final byId = {for (var s in students) s['id'] as String: s};

      final thirty = DateTime.now().subtract(const Duration(days: 30));
      final attRes = await Supabase.instance.client
          .from('attendance')
          .select('student_id, status, date, schedules(start_time, end_time, subjects(name))')
          .gte('date', DateFormat('yyyy-MM-dd').format(thirty))
          .order('date', ascending: false)
          .limit(200);

      final filtered = List<Map<String, dynamic>>.from(attRes).where((a) => ids.contains(a['student_id'])).toList();
      final enriched = filtered.map((a) {
        final sid = a['student_id'] as String?;
        final st = byId[sid];
        return {
          ...a,
          'student_name': st != null ? '${st['first_name']} ${st['last_name']}' : '—',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _items = enriched;
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
    if (_error != null) return _buildError(_error!);
    if (_items.isEmpty) return _buildEmpty('Aucun appel récent');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _items.length,
      itemBuilder: (ctx, i) {
        final a = _items[i];
        final status = a['status'] as String? ?? 'unknown';
        final date = a['date'] != null ? DateTime.tryParse(a['date'].toString()) : null;
        final sched = a['schedules'] as Map<String, dynamic>?;
        final subject = sched?['subjects']?['name'] ?? '—';
        final sname = a['student_name'] ?? '—';

        Color c; Color bg; IconData ic;
        switch (status) {
          case 'present': c = Colors.green; bg = const Color(0xFFDCFCE7); ic = Icons.check_circle; break;
          case 'absent': c = Colors.red; bg = const Color(0xFFFEE2E2); ic = Icons.cancel; break;
          case 'retard': c = Colors.orange; bg = const Color(0xFFFEF3C7); ic = Icons.access_time; break;
          default: c = Colors.grey; bg = const Color(0xFFF3F4F6); ic = Icons.help;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: bg, child: Icon(ic, color: c, size: 18)),
            title: Text(sname, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('$subject • ${date != null ? DateFormat('dd/MM/yyyy').format(date) : '—'}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w700)),
            ),
          ),
        );
      },
    );
  }
}

// ==================== ONGLET RAPPORTS ====================
class _ReportsTab extends StatefulWidget {
  final String classId;
  final String schoolId;
  const _ReportsTab({required this.classId, required this.schoolId});

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
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
      final stRes = await Supabase.instance.client.from('students').select('id').eq('class_id', widget.classId);
      final students = List<Map<String, dynamic>>.from(stRes);
      final ids = students.map((s) => s['id'] as String).toList();
      final total = students.length;

      final grRes = await Supabase.instance.client
          .from('grades')
          .select('score, max_score, coefficient, student_id')
          .eq('school_id', widget.schoolId);
      final allG = List<Map<String, dynamic>>.from(grRes);
      final cg = allG.where((g) => ids.contains(g['student_id'])).toList();

      double tw = 0; int tc = 0; int b8 = 0, b810 = 0, a10 = 0;
      for (final sid in ids) {
        final sg = cg.where((g) => g['student_id'] == sid).toList();
        double sw = 0; int sc = 0;
        for (final g in sg) {
          final score = (g['score'] as num).toDouble();
          final max = (g['max_score'] as num?)?.toDouble() ?? 20.0;
          final coef = (g['coefficient'] as num?)?.toInt() ?? 1;
          final norm = max > 0.0 ? ((score / max) * 20).toDouble() : 0.0;
          sw += norm * coef; sc += coef;
        }
        final avg = sc > 0 ? (sw / sc).toDouble() : 0.0;
        tw += avg; tc++;
        if (avg < 8) b8++; else if (avg < 10) b810++; else a10++;
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
        if (st == 'present') pr++; else if (st == 'absent') ab++; else if (st == 'retard') re++;
      }

      if (mounted) {
        setState(() {
          _stats = {
            'total': total,
            'class_avg': tc > 0 ? (tw / tc).toDouble() : 0.0,
            'below_8': b8, 'between_8_10': b810, 'above_10': a10,
            'success_rate': total > 0 ? ((a10 / total) * 100).toDouble() : 0.0,
            'attendance': {'present': pr, 'absent': ab, 'retard': re, 'total': ca.length},
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
    if (_error != null) return _buildError(_error!);
    if (_stats.isEmpty) return _buildEmpty('Aucune donnée');

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
          _StatCard(title: 'Élèves', value: t.toString(), icon: Icons.people, color: Colors.blue),
          const SizedBox(height: 12),
          _StatCard(title: 'Moyenne classe', value: avg.toStringAsFixed(2), icon: Icons.school, color: AppTheme.violet),
          const SizedBox(height: 12),
          _StatCard(title: 'Taux réussite', value: '${sr.toStringAsFixed(1)}%', icon: Icons.check_circle, color: Colors.green),
          const SizedBox(height: 24),
          const Text('Répartition des moyennes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.nightBlue)),
          const SizedBox(height: 12),
          _DistributionBar(b8: b8, b810: b810, a10: a10, total: t),
          const SizedBox(height: 24),
          const Text('Présences (30 jours)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.nightBlue)),
          const SizedBox(height: 12),
          _AttSummary(att),
        ],
      ),
    );
  }
}

// ==================== WIDGETS COMMUNS ====================
Widget _buildError(String m) {
  return Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 16),
      Text(m, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
    ]),
  ));
}

Widget _buildEmpty(String m) {
  return Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
      const SizedBox(height: 16),
      Text(m, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
    ]),
  ));
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (color == Colors.blue) bg = const Color(0xFFDBEAFE);
    else if (color == Colors.green) bg = const Color(0xFFDCFCE7);
    else bg = const Color(0xFFF3E8FF);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final int b8, b810, a10, total;
  const _DistributionBar({required this.b8, required this.b810, required this.a10, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
      child: const Center(child: Text('Aucune note')),
    );
    final r = b8 / total; final o = b810 / total; final g = a10 / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              if (r > 0) Expanded(flex: (r * 100).round(), child: Container(height: 16, color: Colors.red)),
              if (o > 0) Expanded(flex: (o * 100).round(), child: Container(height: 16, color: Colors.orange)),
              if (g > 0) Expanded(flex: (g * 100).round(), child: Container(height: 16, color: Colors.green)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 8, children: [
          _LegendDot(color: Colors.red, label: 'Rouge (< 8): $b8'),
          _LegendDot(color: Colors.orange, label: 'Orange (8-10): $b810'),
          _LegendDot(color: Colors.green, label: 'Vert (≥ 10): $a10'),
        ]),
      ],
    );
  }
}

class _AttSummary extends StatelessWidget {
  final Map<String, dynamic> att;
  const _AttSummary(this.att);

  @override
  Widget build(BuildContext context) {
    final p = att['present'] as int? ?? 0;
    final a = att['absent'] as int? ?? 0;
    final r = att['retard'] as int? ?? 0;
    final t = att['total'] as int? ?? 0;
    return Row(children: [
      _AttItem('Présents', p, Colors.green),
      const SizedBox(width: 8),
      _AttItem('Absents', a, Colors.red),
      const SizedBox(width: 8),
      _AttItem('Retards', r, Colors.orange),
      const SizedBox(width: 8),
      _AttItem('Total', t, Colors.grey),
    ]);
  }
}

class _AttItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AttItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (color == Colors.green) bg = const Color(0xFFDCFCE7);
    else if (color == Colors.red) bg = const Color(0xFFFEE2E2);
    else if (color == Colors.orange) bg = const Color(0xFFFEF3C7);
    else bg = const Color(0xFFF3F4F6);

    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(children: [
            Text(value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}