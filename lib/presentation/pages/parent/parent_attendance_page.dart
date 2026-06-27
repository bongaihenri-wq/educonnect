// lib/presentation/pages/parent/parent_attendance_page.dart
import 'package:educonnect/services/child_detail_service.dart';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../admin/widgets/period_selector.dart'; // ✅ AJOUTÉ
import 'widgets/presence_stats_cards.dart';
import 'widgets/presence_filter_bar.dart';
import 'widgets/presence_table_widget.dart';

class ParentAttendancePage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final bool isEmbedded;
  // ✅ PARAMÈTRES PÉRIODES AJOUTÉS
  final List<Map<String, dynamic>> periods;
  final Map<String, dynamic>? selectedPeriod;
  final ValueChanged<Map<String, dynamic>?> onPeriodChanged;

  const ParentAttendancePage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.isEmbedded = false,
    this.periods = const [], // ✅ AJOUTÉ
    this.selectedPeriod, // ✅ AJOUTÉ
    required this.onPeriodChanged, // ✅ AJOUTÉ
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
  
  // ✅ SUPPRIMÉ : _selectedPeriod String hardcodé
  // ✅ SUPPRIMÉ : _selectedDate
  
  String _selectedSubject = 'Tous';

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

  // ✅ NOUVEAU : Filtrer par période réelle (start_date / end_date)
  void _applyPeriodFilter(Map<String, dynamic>? period) {
    if (period == null) {
      setState(() => _filteredAttendance = _allAttendance);
      _applySubjectFilter();
      return;
    }

    final startDate = period['start_date'] as String?;
    final endDate = period['end_date'] as String?;

    if (startDate == null || endDate == null) {
      setState(() => _filteredAttendance = _allAttendance);
      _applySubjectFilter();
      return;
    }

    var filtered = _allAttendance.where((a) {
      final date = DateTime.parse(a['date'] as String);
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();

    setState(() => _filteredAttendance = filtered);
    _applySubjectFilter();
  }

  void _applySubjectFilter() {
    if (_selectedSubject == 'Tous') return;
    
    setState(() {
      _filteredAttendance = _filteredAttendance.where((a) {
        final subject = a['schedules']?['subjects']?['name'] as String?;
        return subject == _selectedSubject;
      }).toList();
    });
  }

  // ✅ MODIFIÉ : Utilise le PeriodSelector au lieu du filter bar hardcodé
  void _onPeriodChanged(Map<String, dynamic>? period) {
    widget.onPeriodChanged(period);
    _applyPeriodFilter(period);
  }

  void _onSubjectChanged(String subject) {
    setState(() => _selectedSubject = subject);
    // Re-appliquer le filtre période + sujet
    _applyPeriodFilter(widget.selectedPeriod);
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
                // ✅ REMPLACÉ : PresenceFilterBar par PeriodSelector
                if (widget.periods.isNotEmpty)
                  SliverToBoxAdapter(
                    child: PeriodSelector(
                      periods: widget.periods,
                      selectedPeriod: widget.selectedPeriod,
                      onPeriodChanged: _onPeriodChanged,
                    ),
                  ),
                // ✅ FILTRE MATIÈRE CONSERVÉ (plus simple)
                SliverToBoxAdapter(
                  child: _buildSubjectFilter(),
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

  // ✅ NOUVEAU : Filtre matière simplifié
  Widget _buildSubjectFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.violet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.book_outlined,
              color: AppTheme.violet,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Matière',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSubject,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.violet,
                      size: 20,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.nightBlue,
                    ),
                    items: _availableSubjects.map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _onSubjectChanged(val);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}