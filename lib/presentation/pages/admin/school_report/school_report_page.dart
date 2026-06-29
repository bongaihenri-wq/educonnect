// lib/presentation/pages/admin/school_report/school_report_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/theme.dart';
import '../../../../services/period_service.dart';
import '../../../blocs/auth_bloc/auth_bloc.dart';
import '../../../blocs/school_report/school_report_bloc.dart';
import '../../../blocs/school_report/school_report_event.dart';
import '../../../blocs/school_report/school_report_state.dart';
import 'widgets/attendance_tab.dart';
import 'widgets/export_menu.dart';
import 'widgets/grades_tab.dart';
import 'widgets/report_filters.dart';

class SchoolReportPage extends StatefulWidget {
  const SchoolReportPage({super.key});

  @override
  State<SchoolReportPage> createState() => _SchoolReportPageState();
}

class _SchoolReportPageState extends State<SchoolReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _periodService = PeriodService();
  final _schoolReportBloc = SchoolReportBloc();
  final _supabase = Supabase.instance.client;

  String? _schoolId;
  List<Map<String, dynamic>> _academicPeriods = [];
  Map<String, dynamic>? _selectedPeriod;
  String? _selectedClassId;
  String? _selectedStudentId;
  String? _selectedSubjectId;
  String? _selectedTeacherId;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _teachers = [];
  bool _loadingPeriods = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      _schoolId = state.schoolId;
      if (_schoolId != null) {
        await Future.wait([
          _loadPeriods(),
          _loadClasses(),
          _loadSubjects(),
          _loadTeachers(),
        ]);
        _loadReport();
      }
    }
  }

  Future<void> _loadPeriods() async {
    setState(() => _loadingPeriods = true);
    try {
      _academicPeriods = await _periodService.getAllPeriods(_schoolId!);
      
      print('📅 Périodes chargées: ${_academicPeriods.length}');
      for (final p in _academicPeriods) {
        print('   - ${p['name']}: id=${p['id']}');
      }
      
      final current = await _periodService.getCurrentPeriod(_schoolId!);
      print('📅 Current period: ${current?['name']}');
      
      if (mounted) {
        setState(() {
          _selectedPeriod = current;
          _loadingPeriods = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement périodes: $e');
      if (mounted) setState(() => _loadingPeriods = false);
    }
  }

  Future<void> _loadClasses() async {
    try {
      final response = await _supabase
          .from('classes')
          .select('id, level, name')
          .eq('school_id', _schoolId!)
          .order('level');
      if (mounted) {
        setState(() => _classes = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      print('Erreur chargement classes: $e');
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final response = await _supabase
          .from('subjects')
          .select('id, name')
          .eq('school_id', _schoolId!)
          .order('name');
      if (mounted) {
        setState(() => _subjects = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      print('Erreur chargement matières: $e');
    }
  }

  Future<void> _loadTeachers() async {
    try {
      final response = await _supabase
          .from('app_users')
          .select('id, first_name, last_name')
          .eq('school_id', _schoolId!)
          .eq('role', 'teacher')
          .order('last_name');
      if (mounted) {
        setState(() => _teachers = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      print('Erreur chargement enseignants: $e');
    }
  }

  /// ✅ Vérifie si une période est dynamique (id commence par "dynamic_")
  bool _isDynamicPeriod(Map<String, dynamic>? period) {
    if (period == null) return false;
    final id = period['id'] as String?;
    return id != null && id.startsWith('dynamic_');
  }

  void _loadReport() {
    if (_schoolId == null) return;
    
    String? periodId;
    String? startDate;
    String? endDate;
    
    if (_selectedPeriod != null) {
      if (_isDynamicPeriod(_selectedPeriod)) {
        // Période dynamique : utiliser les dates directement
        startDate = _selectedPeriod!['start_date'] as String?;
        endDate = _selectedPeriod!['end_date'] as String?;
        print('📅 Période dynamique: $startDate → $endDate');
      } else {
        // Période académique : utiliser l'id
        periodId = _selectedPeriod!['id'] as String?;
        print('📅 Période académique: id=$periodId');
      }
    }
    
    print('🎯 _loadReport: periodId=$periodId, startDate=$startDate, endDate=$endDate');
    
    _schoolReportBloc.add(LoadSchoolReportRequested(
      schoolId: _schoolId!,
      periodId: periodId,
      startDate: startDate,
      endDate: endDate,
      classId: _selectedClassId,
      studentId: _selectedStudentId,
      subjectId: _selectedSubjectId,
      teacherId: _selectedTeacherId,
    ));
  }

  void _loadMore(String reportType) {
    if (_schoolId == null) return;
    
    String? periodId;
    String? startDate;
    String? endDate;
    
    if (_selectedPeriod != null) {
      if (_isDynamicPeriod(_selectedPeriod)) {
        startDate = _selectedPeriod!['start_date'] as String?;
        endDate = _selectedPeriod!['end_date'] as String?;
      } else {
        periodId = _selectedPeriod!['id'] as String?;
      }
    }
    
    _schoolReportBloc.add(LoadMoreReportRequested(
      schoolId: _schoolId!,
      periodId: periodId,
      startDate: startDate,
      endDate: endDate,
      classId: _selectedClassId,
      studentId: _selectedStudentId,
      subjectId: _selectedSubjectId,
      teacherId: _selectedTeacherId,
      reportType: reportType,
    ));
  }

  void _onPeriodChanged(Map<String, dynamic>? period) {
    print('🎯 _onPeriodChanged: ${period?['name']}');
    setState(() => _selectedPeriod = period);
    _loadReport();
  }

  void _onClassChanged(String? classId) {
    setState(() {
      _selectedClassId = classId;
      _selectedStudentId = null;
    });
    _loadReport();
  }

  void _onSubjectChanged(String? subjectId) {
    setState(() => _selectedSubjectId = subjectId);
    _loadReport();
  }

  void _onTeacherChanged(String? teacherId) {
    setState(() => _selectedTeacherId = teacherId);
    _loadReport();
  }

  void _onStudentChanged(String? studentId) {
    setState(() => _selectedStudentId = studentId);
    _loadReport();
  }

  void _exportReport(String format) {
    final state = _schoolReportBloc.state;
    if (state is! SchoolReportLoaded) return;

    final reportType = _tabController.index == 0 ? 'attendance' : 'grades';
    final data = _tabController.index == 0
        ? state.attendanceData
        : state.gradesData;

    _schoolReportBloc.add(ExportSchoolReportRequested(
      format: format,
      reportType: reportType,
      data: data,
    ));
  }

  void _shareFile(String filePath) {
    Share.shareXFiles(
      [XFile(filePath)],
      text: 'Rapport EduConnect',
      subject: 'Export EduConnect',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _schoolReportBloc,
      child: BlocListener<SchoolReportBloc, SchoolReportState>(
        listener: (context, state) {
          if (state is SchoolReportExportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✅ Export réussi !',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Fichier: ${state.filePath.split('/').last}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text(
                      '💡 Le fichier est sauvegardé dans :\n'
                      '• Téléchargements → EduConnect (public)\n'
                      '• Dossier local de l\'app (privé)',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 8),
                backgroundColor: Colors.green.shade700,
                action: SnackBarAction(
                  label: '📤 PARTAGER',
                  textColor: Colors.white,
                  onPressed: () => _shareFile(state.filePath),
                ),
              ),
            );
          } else if (state is SchoolReportExportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is SchoolReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.bisLight,
          appBar: AppBar(
            backgroundColor: AppTheme.violet,
            foregroundColor: Colors.white,
            title: const Text('Rapport École'),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.calendar_today), text: 'Assiduité'),
                Tab(icon: Icon(Icons.school), text: 'Notes'),
              ],
            ),
            actions: [
              ExportMenu(onExport: _exportReport),
            ],
          ),
          body: Column(
            children: [
              // ✅ ReportFilters contient PeriodSelector
              ReportFilters(
                academicPeriods: _academicPeriods,
                selectedPeriod: _selectedPeriod,
                loadingPeriods: _loadingPeriods,
                classes: _classes,
                subjects: _subjects,
                teachers: _teachers,
                selectedClassId: _selectedClassId,
                selectedSubjectId: _selectedSubjectId,
                selectedTeacherId: _selectedTeacherId,
                selectedStudentId: _selectedStudentId,
                onPeriodChanged: _onPeriodChanged,
                onClassChanged: _onClassChanged,
                onSubjectChanged: _onSubjectChanged,
                onTeacherChanged: _onTeacherChanged,
                onStudentChanged: _onStudentChanged,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    AttendanceTab(
                      bloc: _schoolReportBloc,
                      onLoadMore: () => _loadMore('attendance'),
                    ),
                    GradesTab(
                      bloc: _schoolReportBloc,
                      onLoadMore: () => _loadMore('grades'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _schoolReportBloc.close();
    super.dispose();
  }
}