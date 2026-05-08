// lib/presentation/pages/parent/child_detail_page.dart
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '/services/child_detail_service.dart';
import 'widgets/grades_tab.dart';
import 'widgets/timetable_tab.dart';
import '../parent/widgets/comments/comments_tab.dart';
import 'parent_attendance_page.dart'; // ✅ Utilise le widget unifié

class ChildDetailPage extends StatefulWidget {
  final String studentName;
  final String studentMatricule;
  final String className;
  final String? parentName;
  final String schoolName;
  final String studentId;
  final int initialTab;

  const ChildDetailPage({
    super.key,
    required this.studentName,
    required this.studentMatricule,
    required this.className,
    this.parentName,
    required this.schoolName,
    required this.studentId,
    this.initialTab = 0,
  });

  @override
  State<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends State<ChildDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = ChildDetailService();
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _timetable = [];
  List<Map<String, dynamic>> _comments = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4, // ✅ 4 onglets au lieu de 5
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      _service.getAttendance(widget.studentId),
      _service.getGrades(widget.studentId),
      _service.getTimetable(widget.studentId),
      _service.getComments(widget.studentId),
      _service.getStats(widget.studentId),
    ]);
    
    setState(() {
      _attendance = results[0] as List<Map<String, dynamic>>;
      _grades = results[1] as List<Map<String, dynamic>>;
      _timetable = results[2] as List<Map<String, dynamic>>;
      _comments = results[3] as List<Map<String, dynamic>>;
      _stats = results[4] as Map<String, dynamic>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        title: const Text('Suivi de l\'élève'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            // ✅ SUPPRIMÉ : Tab(icon: Icon(Icons.dashboard), text: 'Résumé'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Présences'),
            Tab(icon: Icon(Icons.school), text: 'Notes'),
            Tab(icon: Icon(Icons.schedule), text: 'Emploi du temps'),
            Tab(icon: Icon(Icons.chat), text: 'Commentaires'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ✅ SUPPRIMÉ : SummaryTab(...)
                ParentAttendancePage(
                  studentId: widget.studentId,
                  studentName: widget.studentName,
                  isEmbedded: true, // ✅ Mode intégré (pas d'AppBar)
                ), // ✅ Utilise le widget unifié avec filtres
                GradesTab(grades: _grades, stats: _stats),
                TimetableTab(timetable: _timetable),
                CommentsTab(
                  comments: _comments,
                  studentId: widget.studentId,
                  parentName: widget.parentName ?? 'Parent',
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}