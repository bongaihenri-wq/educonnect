// lib/presentation/pages/parent/parent_attendance_page.dart
import 'package:educonnect/services/child_detail_service.dart';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'widgets/presence_stats_cards.dart';
import 'widgets/presence_filter_bar.dart';
import 'widgets/presence_table_widget.dart';

class ParentAttendancePage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final bool isEmbedded;

  const ParentAttendancePage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.isEmbedded = false,
  });

  @override
  State<ParentAttendancePage> createState() => _ParentAttendancePageState();
}

class _ParentAttendancePageState extends State<ParentAttendancePage> {
  final _service = ChildDetailService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allAttendance = [];
  List<Map<String, dynamic>> _filteredAttendance = [];
  List<String> _availableSubjects = [];
  
  String _selectedPeriod = 'Tout';
  String _selectedSubject = 'Tous';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final attendance = await _service.getAttendance(widget.studentId);
    final subjects = attendance
        .map((a) => a['schedules']?['subjects']?['name'] as String?)
        .where((s) => s != null)
        .toSet()
        .cast<String>()
        .toList();

    setState(() {
      _allAttendance = attendance;
      _filteredAttendance = attendance;
      _availableSubjects = ['Tous', ...subjects];
      _isLoading = false;
    });
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_allAttendance);

    if (_selectedPeriod == 'Jour' && _selectedDate != null) {
      filtered = filtered.where((a) {
        final date = DateTime.parse(a['date'] as String);
        return date.year == _selectedDate!.year &&
               date.month == _selectedDate!.month &&
               date.day == _selectedDate!.day;
      }).toList();
    } else if (_selectedPeriod == 'Mois' && _selectedDate != null) {
      filtered = filtered.where((a) {
        final date = DateTime.parse(a['date'] as String);
        return date.year == _selectedDate!.year &&
               date.month == _selectedDate!.month;
      }).toList();
    } else if (_selectedPeriod == 'Trimestre' && _selectedDate != null) {
      final trimestre = _getTrimestre(_selectedDate!.month);
      filtered = filtered.where((a) {
        final date = DateTime.parse(a['date'] as String);
        return date.year == _selectedDate!.year &&
               _getTrimestre(date.month) == trimestre;
      }).toList();
    }

    if (_selectedSubject != 'Tous') {
      filtered = filtered.where((a) {
        final subject = a['schedules']?['subjects']?['name'] as String?;
        return subject == _selectedSubject;
      }).toList();
    }

    setState(() {
      _filteredAttendance = filtered;
    });
  }

  int _getTrimestre(int month) {
    if (month <= 3) return 1;
    if (month <= 6) return 2;
    if (month <= 9) return 3;
    return 4;
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
      if (period == 'Tout') {
        _selectedDate = null;
      } else {
        _selectedDate = DateTime.now();
      }
    });
    _applyFilters();
  }

  void _onSubjectChanged(String subject) {
    setState(() => _selectedSubject = subject);
    _applyFilters();
  }

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return _buildContent();
    }

    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        backgroundColor: AppTheme.bisLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.nightBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.violet),
            const SizedBox(width: 10),
            Text(
              'Présences',
              style: TextStyle(
                color: AppTheme.nightBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.violet))
        : SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PresenceStatsCards(attendance: _filteredAttendance),
                ),
                SliverToBoxAdapter(
                  child: PresenceFilterBar(
                    selectedPeriod: _selectedPeriod,
                    selectedSubject: _selectedSubject,
                    selectedDate: _selectedDate,
                    availableSubjects: _availableSubjects,
                    onPeriodChanged: _onPeriodChanged,
                    onSubjectChanged: _onSubjectChanged,
                    onDateChanged: _onDateChanged,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: PresenceTableWidget(attendance: _filteredAttendance),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
              ],
            ),
          );
  }
}