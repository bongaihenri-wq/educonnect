// lib/presentation/pages/teacher/teacher_reports_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../blocs/report/report_bloc.dart';
import '../../blocs/report/report_events.dart';
import '../../blocs/report/report_state.dart';
import 'widgets/report/report_period_selector.dart';
import 'widgets/report/report_class_student_selector.dart';
import 'widgets/report/report_class_kpi_cards.dart';
import 'widgets/report/report_class_attendance_stats.dart';
import 'widgets/report/report_class_grades_stats.dart';
import 'widgets/report/report_student_attendance_timeline.dart';
import 'widgets/report/report_student_grades_table.dart';
import 'widgets/report/report_student_evolution_chart.dart';
import 'widgets/report/report_comments_section.dart';

class TeacherReportsPage extends StatefulWidget {
  final String teacherId;
  final String schoolId;

  const TeacherReportsPage({
    super.key,
    required this.teacherId,
    required this.schoolId, required String subject,
  });

  @override
  State<TeacherReportsPage> createState() => _TeacherReportsPageState();
}

class _TeacherReportsPageState extends State<TeacherReportsPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportBloc(
        reportRepository: ReportRepository(),
        classRepository: context.read<ClassRepository>(),
        studentRepository: context.read<StudentRepository>(),
        teacherId: widget.teacherId,
        schoolId: widget.schoolId,
      )..add(ReportLoadClassesRequested(widget.teacherId)),
      child: _TeacherReportsView(teacherId: widget.teacherId),
    );
  }
}

class _TeacherReportsView extends StatelessWidget {
  final String teacherId;
  const _TeacherReportsView({required this.teacherId});

  @override
  Widget build(BuildContext context) {
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
            Icon(Icons.bar_chart, color: AppTheme.violet),
            const SizedBox(width: 10),
            const Text(
              'Rapports',
              style: TextStyle(
                color: AppTheme.nightBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.violet),
            onPressed: () {
              context.read<ReportBloc>().add(
                ReportLoadClassesRequested(teacherId),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state.error != null && state.error!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.classes.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.violet));
          }

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                // ─── SÉLECTEURS FIXES EN HAUT ─────────────────
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      ReportPeriodSelector(
                        periods: state.availablePeriods,
                        selectedPeriod: state.selectedPeriod,
                        onPeriodSelected: (period) {
                          context.read<ReportBloc>().add(ReportPeriodSelected(period));
                        },
                      ),
                      const ReportClassStudentSelector(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // ─── CONTENU ────────────────────────────────
                if (state.selectedClassId != null && state.isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.violet)),
                    ),
                  )
                else if (state.selectedClassId != null && state.viewMode == ReportViewMode.classView)
                  SliverToBoxAdapter(
                    child: _buildClassView(state),
                  )
                else if (state.selectedClassId != null && state.viewMode == ReportViewMode.studentView)
                  SliverToBoxAdapter(
                    child: _buildStudentView(state),
                  )
                else if (state.selectedClassId == null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            state.classes.isEmpty 
                              ? 'Aucune classe assignée'
                              : 'Sélectionnez une classe',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassView(ReportState state) {
    if (state.classAttendance == null || state.classGrades == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée pour cette période',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ReportClassKPICards(attendance: state.classAttendance!, grades: state.classGrades!),
        ReportClassAttendanceStats(stats: state.classAttendance!),
        ReportClassGradesStats(stats: state.classGrades!),
          const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStudentView(ReportState state) {
    if (state.studentAttendance == null || state.studentGrades == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée pour cet élève',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ReportStudentAttendanceTimeline(stats: state.studentAttendance!),
        ReportStudentGradesTable(stats: state.studentGrades!),
        //const ReportStudentEvolutionChart(),
        const ReportCommentsSection(),
        const SizedBox(height: 24),
      ],
    );
  }
}