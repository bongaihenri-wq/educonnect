// lib/presentation/pages/principal/class_detail/attendance_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../services/period_service.dart';
import '../../admin/widgets/period_selector.dart';
import 'widgets/common_widgets.dart';

class AttendanceTab extends StatefulWidget {
  final String classId;
  final String schoolId;
  final List<Map<String, dynamic>> periods;

  const AttendanceTab({
    super.key,
    required this.classId,
    required this.schoolId,
    required this.periods,
  });

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  final _periodService = PeriodService();
  bool _loading = true;
  Map<String, dynamic>? _selectedPeriod;
  List<Map<String, dynamic>> _items = [];
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
      final byId = {for (var s in students) s['id'] as String: s};

      var query = Supabase.instance.client.from('attendance').select(
          'student_id, status, date, schedules(start_time, end_time, subjects(name))');

      if (startDate != null) {
        query = query.gte('date', DateFormat('yyyy-MM-dd').format(startDate));
      }
      if (endDate != null) {
        query = query.lte('date', DateFormat('yyyy-MM-dd').format(endDate));
      }

      final attRes = await query.order('date', ascending: false).limit(200);
      final filtered = List<Map<String, dynamic>>.from(attRes)
          .where((a) => ids.contains(a['student_id']))
          .toList();
      final enriched = filtered.map((a) {
        final sid = a['student_id'] as String?;
        final st = byId[sid];
        return {
          ...a,
          'student_name':
              st != null ? '${st['first_name']} ${st['last_name']}' : '—',
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
                  : _items.isEmpty
                      ? buildEmpty('Aucun appel')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: _items.length,
                          itemBuilder: (ctx, i) {
                            final a = _items[i];
                            final status = a['status'] as String? ?? 'unknown';
                            final date = a['date'] != null
                                ? DateTime.tryParse(a['date'].toString())
                                : null;
                            final sched =
                                a['schedules'] as Map<String, dynamic>?;
                            final subject = sched?['subjects']?['name'] ?? '—';
                            final sname = a['student_name'] ?? '—';

                            Color c;
                            Color bg;
                            IconData ic;
                            switch (status) {
                              case 'present':
                                c = Colors.green;
                                bg = const Color(0xFFDCFCE7);
                                ic = Icons.check_circle;
                                break;
                              case 'absent':
                                c = Colors.red;
                                bg = const Color(0xFFFEE2E2);
                                ic = Icons.cancel;
                                break;
                              case 'retard':
                                c = Colors.orange;
                                bg = const Color(0xFFFEF3C7);
                                ic = Icons.access_time;
                                break;
                              default:
                                c = Colors.grey;
                                bg = const Color(0xFFF3F4F6);
                                ic = Icons.help;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: bg,
                                    child: Icon(ic, color: c, size: 18)),
                                title: Text(sname,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                    '$subject • ${date != null ? DateFormat('dd/MM/yyyy').format(date) : '—'}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280))),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(status.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: c,
                                          fontWeight: FontWeight.w700)),
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
