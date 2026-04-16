import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Tes imports BLoC
import '/presentation/blocs/attendance/attendance_bloc.dart';
import '/presentation/blocs/attendance/attendance_event.dart';
import '/presentation/blocs/attendance/attendance_state.dart';

// Tes imports modèles
import '../../../data/models/class_model.dart';
import '../../../data/models/course_model.dart';

// Tes nouveaux composants (vérifie bien les chemins)
import 'widgets/attendance_header.dart';
import 'widgets/class_selector_card.dart';
import 'widgets/course_selector_card.dart';
import 'widgets/student_attendance_tile.dart';
import 'widgets/attendance_bottom_bar.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key, required String classId, required String className, String? subjectId, String? subjectName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AttendanceBloc(
        attendanceRepository: context.read(),
        classRepository: context.read(),
        studentRepository: context.read(),
        courseRepository: context.read(),
      )..add(const AttendanceLoadClassesRequested(classId: '', courseId: '')),
      child: const AttendanceView(),
    );
  }
}

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Couleur Bis
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          if (state.isLoading && state.classes.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            );
          }

          return CustomScrollView(
            slivers: [
              // 1. HEADER (Gradient + Date)
              SliverToBoxAdapter(
                child: AttendanceHeader(
                  selectedDate: state.selectedDate,
                  className: state.selectedClass?.name,
                  studentCount: state.students.length,
                  onDateTap: () => _selectDate(context, state.selectedDate),
                  onBackPressed: () => Navigator.pop(context),
                ),
              ),

              // 2. CONTENU (Sélecteurs + Liste)
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Sélecteur de classe
                    ClassSelectorCard(
                      classes: state.classes,
                      selectedClass: state.selectedClass,
                      onClassSelected: (ClassModel classe) {
                        context.read<AttendanceBloc>().add(AttendanceClassSelected(classe));
                      },
                    ),
                    const SizedBox(height: 20),

                    // Sélecteur de cours (si classe sélectionnée)
                    if (state.selectedClass != null) ...[
                      CourseSelectorCard(
                        courses: state.availableCourses,
                        currentCourse: state.currentCourse,
                        isAutoDetected: state.currentCourse != null,
                        onCourseChanged: (course) {
                          context.read<AttendanceBloc>().add(AttendanceCourseChanged(course));
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Liste des élèves
                      _buildStudentsListSection(context, state),
                    ],

                    const SizedBox(height: 100), // Espace pour la barre du bas
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      // 3. BARRE DE VALIDATION
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
            onValidate: state.isComplete && !state.isSubmitting
                ? () => context.read<AttendanceBloc>().add(
                      AttendanceSubmitRequested(date: state.selectedDate),
                    )
                : null,
          );
        },
      ),
    );
  }

  // --- Helpers de construction ---

  Widget _buildStudentsListSection(BuildContext context, AttendanceState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.students.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('Aucun élève dans cette classe')),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStudentsHeader(context, state.students.length),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.students.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
            itemBuilder: (context, index) {
              final student = state.students[index];
              return StudentAttendanceTile(
                student: student,
                status: state.attendanceRecords[student.id],
                onStatusChanged: (status) {
                  context.read<AttendanceBloc>().add(
                        AttendanceStudentStatusUpdated(
                          studentId: student.id,
                          status: status,
                        ),
                      );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Élèves ($count)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: () => context.read<AttendanceBloc>().add(const AttendanceMarkAllPresent()),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Tous présents'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF14B8A6)),
          ),
        ],
      ),
    );
  }

  // --- Logique UI ---

  void _handleStateChanges(BuildContext context, AttendanceState state) {
    if (state.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Appel enregistré avec succès !'),
          backgroundColor: Color(0xFF14B8A6),
        ),
      );
      Navigator.pop(context);
    }
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: const Color(0xFFFB7185),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      context.read<AttendanceBloc>().add(AttendanceDateChanged(picked));
    }
  }
}