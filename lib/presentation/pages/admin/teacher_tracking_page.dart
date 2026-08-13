// lib/presentation/pages/admin/teacher_tracking_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';

class TeacherTrackingPage extends StatefulWidget {
  const TeacherTrackingPage({super.key});

  @override
  State<TeacherTrackingPage> createState() => _TeacherTrackingPageState();
}

class _TeacherTrackingPageState extends State<TeacherTrackingPage> {
  final _client = Supabase.instance.client;

  String? _teacherId;
  String _teacherName = 'Enseignant';
  String? _schoolId;

  bool _argsLoaded = false;
  bool _isLoading = true;
  String? _error;

  String _period = 'month'; // 'week' | 'month' | 'days30'

  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _calls = []; // 1 élément = 1 appel (cours × jour)
  int _plannedCourses = 0;

  static const _weekdayLabels = [
    '',
    'lun.',
    'mar.',
    'mer.',
    'jeu.',
    'ven.',
    'sam.',
    'dim.'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _argsLoaded = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _teacherId = args?['teacher_id'] as String?;
      _teacherName = (args?['teacher_name'] as String?) ?? 'Enseignant';
      _schoolId = args?['school_id'] as String?;
      _loadData();
    }
  }

  // ---------- Période ----------

  DateTime get _periodEnd => DateTime.now();

  DateTime get _periodStart {
    final now = DateTime.now();
    switch (_period) {
      case 'week':
        return now.subtract(const Duration(days: 6));
      case 'days30':
        return now.subtract(const Duration(days: 29));
      case 'month':
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------- Chargement ----------

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_teacherId == null || _teacherId!.isEmpty) {
        throw 'Identifiant enseignant manquant';
      }

      // 1. Cours programmés de l'enseignant
      var query = _client
          .from('schedules')
          .select(
              'id, class_id, day_of_week, start_time, end_time, classes(name)')
          .eq('teacher_id', _teacherId!)
          .eq('is_active', true);
      if (_schoolId != null && _schoolId!.isNotEmpty) {
        query = query.eq('school_id', _schoolId!);
      }
      final schedulesData = await query;
      _schedules = List<Map<String, dynamic>>.from(schedulesData);

      // 2. Appels effectués sur la période (via les ids de cours de l'enseignant)
      _calls = [];
      if (_schedules.isNotEmpty) {
        final scheduleIds = _schedules.map((s) => s['id'].toString()).toList();
        final attendanceData = await _client
            .from('attendance')
            .select('date, status, updated_at, created_at, schedule_id')
            .inFilter('schedule_id', scheduleIds)
            .gte('date', _formatDate(_periodStart))
            .lte('date', _formatDate(_periodEnd));
        _calls = _buildCalls(List<Map<String, dynamic>>.from(attendanceData));
      }

      // 3. Cours prévus sur la période (jour déclaré du cours, 1=lundi … 7=dimanche)
      _plannedCourses = _countPlannedCourses();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // Regroupe les lignes attendance par (cours × jour) = 1 appel
  List<Map<String, dynamic>> _buildCalls(List<Map<String, dynamic>> rows) {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final row in rows) {
      final scheduleId = row['schedule_id'].toString();
      final dateStr = row['date'].toString();
      final key = '$scheduleId|$dateStr';
      final call = grouped.putIfAbsent(
        key,
        () => {
          'schedule_id': scheduleId,
          'date': dateStr,
          'present': 0,
          'absent': 0,
          'retard': 0,
          'last_call_at': null as String?,
        },
      );

      switch (row['status']) {
        case 'present':
          call['present'] = (call['present'] as int) + 1;
          break;
        case 'absent':
          call['absent'] = (call['absent'] as int) + 1;
          break;
        case 'retard':
          call['retard'] = (call['retard'] as int) + 1;
          break;
      }

      final ts = (row['updated_at'] ?? row['created_at'])?.toString();
      if (ts != null) {
        final prev = call['last_call_at'] as String?;
        if (prev == null || ts.compareTo(prev) > 0) {
          call['last_call_at'] = ts;
        }
      }
    }

    final calls = grouped.values.toList();
    calls.sort((a, b) {
      final cmp = (b['date'] as String)
          .compareTo(a['date'] as String); // plus récent d'abord
      if (cmp != 0) return cmp;
      return _courseStartTime(a['schedule_id'] as String)
          .compareTo(_courseStartTime(b['schedule_id'] as String));
    });
    return calls;
  }

  // Cours prévus = occurrences du day_of_week déclaré dans la période, par cours actif
  int _countPlannedCourses() {
    var count = 0;
    final start =
        DateTime(_periodStart.year, _periodStart.month, _periodStart.day);
    final end = DateTime(_periodEnd.year, _periodEnd.month, _periodEnd.day);

    for (final s in _schedules) {
      final dow = s['day_of_week'] as int?;
      if (dow == null || dow < 1 || dow > 7) continue;
      var d = start;
      while (!d.isAfter(end)) {
        if (d.weekday == dow) count++;
        d = d.add(const Duration(days: 1));
      }
    }
    return count;
  }

  // ---------- Helpers d'affichage ----------

  Map<String, dynamic> _scheduleFor(String scheduleId) {
    return _schedules.firstWhere(
      (s) => s['id'].toString() == scheduleId,
      orElse: () => <String, dynamic>{},
    );
  }

  String _courseStartTime(String scheduleId) =>
      _scheduleFor(scheduleId)['start_time']?.toString() ?? '';

  String _classNameFor(String scheduleId) {
    final c = _scheduleFor(scheduleId)['classes'];
    if (c is Map) return c['name']?.toString() ?? 'Classe ?';
    return 'Classe ?';
  }

  String _courseHoursFor(String scheduleId) {
    final s = _scheduleFor(scheduleId);
    String fmt(dynamic t) {
      final str = t?.toString() ?? '';
      return str.length >= 5 ? str.substring(0, 5) : str;
    }

    final start = fmt(s['start_time']);
    final end = fmt(s['end_time']);
    if (start.isEmpty) return '-';
    return end.isEmpty ? start : '$start–$end';
  }

  String _callHour(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '-';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _dayLabel(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return '${_weekdayLabels[d.weekday]} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: Text(
          'Suivi — $_teacherName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(),
                      const SizedBox(height: 16),
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildCallsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'value': 'week', 'label': '7 derniers jours'},
      {'value': 'month', 'label': 'Ce mois-ci'},
      {'value': 'days30', 'label': '30 derniers jours'},
    ];

    return Wrap(
      spacing: 8,
      children: periods.map((p) {
        final isSelected = _period == p['value'];
        return ChoiceChip(
          label: Text(p['label'] as String),
          selected: isSelected,
          selectedColor: AppTheme.violet,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() => _period = p['value'] as String);
              _loadData();
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard() {
    final callsCount = _calls.length;
    final rate = _plannedCourses > 0
        ? ((callsCount / _plannedCourses) * 100).round()
        : (callsCount > 0 ? 100 : 0);
    final rateColor = rate >= 80
        ? Colors.green
        : rate >= 50
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appels effectués / cours prévus',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryStat(
                    Icons.fact_check, '$callsCount', 'Appels', Colors.green),
                const SizedBox(width: 8),
                _buildSummaryStat(Icons.calendar_month, '$_plannedCourses',
                    'Cours prévus', Colors.blue),
                const SizedBox(width: 8),
                _buildSummaryStat(
                    Icons.percent, '$rate%', 'Réalisation', rateColor),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _plannedCourses > 0
                    ? (callsCount / _plannedCourses).clamp(0.0, 1.0)
                    : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(rateColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallsSection() {
    if (_schedules.isEmpty) {
      return _buildInfoBox(
          Icons.event_busy, 'Aucun cours programmé pour cet enseignant');
    }
    if (_calls.isEmpty) {
      return _buildInfoBox(
          Icons.inbox, 'Aucun appel enregistré sur cette période');
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détail des appels (${_calls.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 44,
                columnSpacing: 16,
                columns: const [
                  DataColumn(
                      label: Text('Jour',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(
                      label: Text('Classe',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(
                      label: Text('Cours',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(
                      label: Text('Appel',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(
                      label: Text('P',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.green))),
                  DataColumn(
                      label: Text('A',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red))),
                  DataColumn(
                      label: Text('R',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.orange))),
                ],
                rows: _calls.map((call) {
                  final scheduleId = call['schedule_id'] as String;
                  return DataRow(
                    cells: [
                      DataCell(Text(_dayLabel(call['date'] as String),
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(_classNameFor(scheduleId),
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(_courseHoursFor(scheduleId),
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(_callHour(call['last_call_at'] as String?),
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${call['present']}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600))),
                      DataCell(Text('${call['absent']}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w600))),
                      DataCell(Text('${call['retard']}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600))),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'P = présents · A = absents · R = retards',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Erreur: $_error', textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
