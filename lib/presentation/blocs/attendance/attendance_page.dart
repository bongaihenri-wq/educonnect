// lib/presentation/pages/teacher/attendance/attendance_page.dart
import 'package:educonnect/data/models/course_model.dart';
import 'package:educonnect/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/attendance/attendance_bloc.dart';
import '../../blocs/attendance/attendance_event.dart';
import '../../blocs/attendance/attendance_state.dart';
import '../../../data/models/attendance_model.dart';
import '/presentation/pages/teacher/widgets/attendance_header.dart';
import '/presentation/pages/teacher/widgets/student_attendance_tile.dart';
import '/presentation/pages/teacher/widgets/attendance_bottom_bar.dart';

class AttendancePage extends StatelessWidget {
  final String classId;
  final String className;
  final String? subjectId;
  final String? subjectName;

  const AttendancePage({
    super.key, 
    required this.classId, 
    required this.className, 
    this.subjectId, 
    this.subjectName
  });

  @override
  Widget build(BuildContext context) {
    return AttendanceView(className: className);
  }
}

class AttendanceView extends StatelessWidget {
  final String className;

  const AttendanceView({
    super.key,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          print('🔥 AttendanceView build:');
          print('🔥 selectedClass: ${state.selectedClass?.name ?? 'NULL'}');
          print('🔥 currentCourse: ${state.currentCourse?.name ?? 'NULL'}');
          print('🔥 students: ${state.students.length}');

          if (state.isLoading && state.students.isEmpty && state.selectedClass == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AttendanceHeader(
                  selectedDate: state.selectedDate,
                  className: state.selectedClass?.name ?? className,
                  studentCount: state.students.length,
                  onDateTap: () => _selectDate(context, state.selectedDate),
                  onBackPressed: () => Navigator.pop(context),
                ),
              ),

              // ✅ CORRIGÉ : Liste fine et épurée
              if (state.currentCourse != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: _buildCourseCard(state.currentCourse!),
                  ),
                ),

              if (state.selectedClass != null && state.students.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  sliver: _buildStudentsList(context, state), // ✅ PASSER context ICI
                )
              else if (state.selectedClass != null && state.students.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              // Espace pour bottom bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state.selectedClass == null || state.students.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return AttendanceBottomBar(
            present: state.presentCount,
            absent: state.absentCount,
            late: state.lateCount,
            remaining: state.remainingCount,
            total: state.students.length,
            percentage: state.completionPercentage,
            isSubmitting: state.isSubmitting,
            buttonText: state.showReplaceDialog
                ? 'Remplacer l\'appel'
                : 'Valider l\'appel (${state.students.length}/${state.students.length})',
            onValidate: state.isComplete && !state.isSubmitting
                ? () {
                    final authState = context.read<AuthBloc>().state;
                    String teacherId = '';
                    String schoolId = '';
                    if (authState is Authenticated) {
                      teacherId = authState.userId;
                      schoolId = authState.schoolId;
                    }
                    
                    context.read<AttendanceBloc>().add(
                      AttendanceSubmitRequested(
                        date: state.selectedDate,
                        teacherId: teacherId,
                        schoolId: schoolId,
                      ),
                    );
                  }
                : null,
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: const Color(0xFF7C3AED), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                Text(
                  '${course.startTime} - ${course.endTime}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CORRIGÉ : Reçoit BuildContext en paramètre
  Widget _buildStudentsList(BuildContext context, AttendanceState state) {
    return SliverMainAxisGroup(
      slivers: [
        // Header compact
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Élèves (${state.students.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                // ✅ Bouton "Tous présents" compact
                Material(
                  color: const Color(0xFF14B8A6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => context.read<AttendanceBloc>().add(const AttendanceMarkAllPresent()), // ✅ context accessible maintenant
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 14, color: const Color(0xFF14B8A6)),
                          const SizedBox(width: 4),
                          Text(
                            'Tous présents',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF14B8A6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✅ LISTE ÉPURÉE : Items compacts
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final student = state.students[index];
              final status = state.attendanceRecords[student.id] ?? AttendanceStatus.present;
              
              return _buildStudentTile(context, student, status, index); // ✅ PASSE context ICI AUSSI
            },
            childCount: state.students.length,
          ),
        ),

        // Footer arrondi
        SliverToBoxAdapter(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(
                left: BorderSide(color: Colors.grey.shade200),
                right: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ CORRIGÉ : Reçoit BuildContext en paramètre
  Widget _buildStudentTile(BuildContext context, student, AttendanceStatus status, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // ✅ TOGGLE RAPIDE : Présent → Absent → Retard → Présent
            AttendanceStatus nextStatus;
            switch (status) {
              case AttendanceStatus.present:
                nextStatus = AttendanceStatus.absent;
                break;
              case AttendanceStatus.absent:
                nextStatus = AttendanceStatus.late;
                break;
              case AttendanceStatus.late:
                nextStatus = AttendanceStatus.present;
                break;
            }
            context.read<AttendanceBloc>().add( // ✅ context accessible maintenant
              AttendanceStudentStatusUpdated(
                studentId: student.id,
                status: nextStatus,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // ✅ Numéro compact
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // ✅ Nom compact
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${student.firstName} ${student.lastName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (student.matricule != null)
                        Text(
                          student.matricule!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),

                // ✅ Badge statut compact (sans texte, juste couleur)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: _getStatusIcon(status, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF14B8A6); // Vert menthe
      case AttendanceStatus.absent:
        return const Color(0xFFFB7185); // Rouge corail
      case AttendanceStatus.late:
        return const Color(0xFFF59E0B); // Orange
    }
  }

  Widget _getStatusIcon(AttendanceStatus status, {double size = 16}) {
    switch (status) {
      case AttendanceStatus.present:
        return Icon(Icons.check, size: size, color: const Color(0xFF14B8A6));
      case AttendanceStatus.absent:
        return Icon(Icons.close, size: size, color: const Color(0xFFFB7185));
      case AttendanceStatus.late:
        return Icon(Icons.access_time, size: size, color: const Color(0xFFF59E0B));
    }
  }

  void _handleStateChanges(BuildContext context, AttendanceState state) {
    if (state.showReplaceDialog && state.warning != null) {
      _showReplaceDialog(context, state);
    }

    if (state.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Appel enregistré avec succès !'),
          backgroundColor: Color(0xFF14B8A6),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
    
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: const Color(0xFFFB7185),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showReplaceDialog(BuildContext context, AttendanceState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 12),
            Text('Appel existant'),
          ],
        ),
        content: Text(
          state.warning!,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AttendanceBloc>().add(
                AttendanceDateChanged(state.selectedDate),
              );
            },
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              
              final authState = context.read<AuthBloc>().state;
              String teacherId = '';
              String schoolId = '';
              if (authState is Authenticated) {
                teacherId = authState.userId;
                schoolId = authState.schoolId;
              }
              
              context.read<AttendanceBloc>().add(
                AttendanceReplaceConfirmed(
                  date: state.selectedDate,
                  teacherId: teacherId,
                  schoolId: schoolId,
                ),
              );
            },
            child: const Text('Remplacer'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7C3AED),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      context.read<AttendanceBloc>().add(AttendanceDateChanged(picked));
    }
  }
}