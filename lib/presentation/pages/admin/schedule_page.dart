// lib/presentation/pages/admin/schedule_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../presentation/blocs/auth_bloc/auth_bloc.dart' as auth;
import 'widgets/schedule/call_status_badge.dart';
import 'widgets/schedule/course_card.dart';
import 'widgets/schedule/current_course_card.dart';
import 'widgets/schedule/date_time_selector.dart';
import 'widgets/schedule/no_course_card.dart';
import 'widgets/schedule/schedule_utils.dart';
import 'widgets/schedule/section_title.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> _dayEntries = [];
  Set<String> _calledScheduleIds = {};
  bool _isLoading = true;
  String? _schoolId;

  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedule();
    });
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final state = context.read<auth.AuthBloc>().state;
      if (state is auth.Authenticated) {
        _schoolId = state.schoolId;
      }

      if (_schoolId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final targetDate = _selectedDateTime;
      final targetWeekday = targetDate.weekday;
      final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

      final response = await Supabase.instance.client
          .from('schedules')
          .select('id, day_of_week, start_time, end_time, room, classes(name, level), subjects(name), app_users(first_name, last_name)')
          .eq('classes.school_id', _schoolId!)
          .eq('day_of_week', targetWeekday)
          .order('start_time');

      final entries = List<Map<String, dynamic>>.from(response);

      if (entries.isNotEmpty) {
        final scheduleIds = entries.map((e) => e['id'] as String).toList();

        final attendanceData = await Supabase.instance.client
            .from('attendance')
            .select('schedule_id')
            .eq('school_id', _schoolId!)
            .eq('date', dateStr);

        _calledScheduleIds = attendanceData
            .where((r) => scheduleIds.contains(r['schedule_id']))
            .map((r) => r['schedule_id'] as String)
            .toSet();
      } else {
        _calledScheduleIds = {};
      }

      setState(() {
        _dayEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur Schedule: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.violet,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
      _loadSchedule();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.violet,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
      _loadSchedule();
    }
  }

  void _resetToNow() {
    setState(() {
      _selectedDateTime = DateTime.now();
    });
    _loadSchedule();
  }

  bool get _isRealtime {
    final now = DateTime.now();
    final diff = now.difference(_selectedDateTime).abs();
    return diff.inMinutes < 2;
  }

  @override
  Widget build(BuildContext context) {
    final targetTimeStr = formatTimeOfDay(TimeOfDay.fromDateTime(_selectedDateTime));

    final currentEntry = _dayEntries.cast<Map<String, dynamic>?>().firstWhere(
      (e) => isCurrentlyRunning(_selectedDateTime, e?['start_time'], e?['end_time']),
      orElse: () => null,
    );

    final upcomingEntries = _dayEntries.where((e) {
      return isUpcomingCourse(_selectedDateTime, e['start_time'], e['end_time']) && e != currentEntry;
    }).toList();

    final pastEntries = _dayEntries.where((e) {
      return isPastCourse(_selectedDateTime, e['end_time']);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text('Emploi du Temps'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedule,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedule,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DateTimeSelector(
                      selectedDateTime: _selectedDateTime,
                      onDateTap: _pickDate,
                      onTimeTap: _pickTime,
                      onReset: _resetToNow,
                      isRealtime: _isRealtime,
                    ),
                    const SizedBox(height: 20),

                    if (currentEntry != null) ...[
                      CurrentCourseCard(
                        entry: currentEntry,
                        isCalled: _calledScheduleIds.contains(currentEntry['id'] as String),
                      ),
                      const SizedBox(height: 24),
                      if (upcomingEntries.isNotEmpty) ...[
                        const SectionTitle(title: 'Prochainement'),
                        const SizedBox(height: 12),
                      ],
                    ] else ...[
                      NoCourseCard(timeStr: targetTimeStr),
                      const SizedBox(height: 24),
                      if (upcomingEntries.isNotEmpty) ...[
                        const SectionTitle(title: 'Prochainement'),
                        const SizedBox(height: 12),
                      ],
                    ],

                    ...upcomingEntries.map((e) => CourseCard(
                          entry: e,
                          isCalled: _calledScheduleIds.contains(e['id'] as String),
                          isPast: false,
                        )),

                    if (pastEntries.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const SectionTitle(title: 'Terminés', color: Colors.grey),
                      const SizedBox(height: 12),
                      ...pastEntries.map((e) => CourseCard(
                            entry: e,
                            isCalled: _calledScheduleIds.contains(e['id'] as String),
                            isPast: true,
                          )),
                    ],

                    if (_dayEntries.isEmpty) ...[
                      const SizedBox(height: 40),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun cours programmé ce jour',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}