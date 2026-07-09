// lib/presentation/pages/principal/class_detail/principal_class_detail_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/theme.dart';
import '../../../../services/period_service.dart';
import 'students_tab.dart';
import 'grades_tab.dart';
import 'attendance_tab.dart';
import 'reports_tab.dart';

class PrincipalClassDetailPage extends StatefulWidget {
  final String classId;
  final String className;
  final String schoolId;

  const PrincipalClassDetailPage({
    super.key,
    required this.classId,
    required this.className,
    required this.schoolId,
  });

  @override
  State<PrincipalClassDetailPage> createState() =>
      _PrincipalClassDetailPageState();
}

class _PrincipalClassDetailPageState extends State<PrincipalClassDetailPage> {
  List<Map<String, dynamic>> _periods = [];
  bool _loadingPeriods = true;

  @override
  void initState() {
    super.initState();
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    try {
      final service = PeriodService();
      final periods = await service.getAllPeriods(widget.schoolId);
      if (mounted) {
        setState(() {
          _periods = periods;
          _loadingPeriods = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPeriods = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.bisLight,
        appBar: AppBar(
          title: Text(
            widget.className,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
        body: _loadingPeriods
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  StudentsTab(
                    classId: widget.classId,
                    schoolId: widget.schoolId,
                    className: widget.className,
                  ),
                  GradesTab(
                    classId: widget.classId,
                    schoolId: widget.schoolId,
                    periods: _periods,
                  ),
                  AttendanceTab(
                    classId: widget.classId,
                    schoolId: widget.schoolId,
                    periods: _periods,
                  ),
                  ReportsTab(
                    classId: widget.classId,
                    schoolId: widget.schoolId,
                    periods: _periods,
                  ),
                ],
              ),
      ),
    );
  }
}
