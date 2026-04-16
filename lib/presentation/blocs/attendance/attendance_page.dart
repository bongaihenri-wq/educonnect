import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Imports de tes Blocs
import '../../blocs/attendance/attendance_bloc.dart';
import '../../blocs/attendance/attendance_event.dart';
import '../../blocs/attendance/attendance_state.dart';

// Imports de tes nouveaux widgets extraits
import 'widgets/attendance_bottom_bar.dart';
import 'widgets/attendance_course_selector.dart';
import 'widgets/attendance_quick_actions.dart';
import 'widgets/attendance_student_tile.dart';
import 'widgets/attendance_timer_badge.dart';
import '/../data/models/attendance_model.dart' hide AttendanceStatus; // Pour AttendanceStatus

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        // Implémentation rapide du listener pour gérer les erreurs ou succès
        if (state.isSubmitting) {
           // Optionnel: afficher un loader global
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text("Appel de présence"),
            actions: const [AttendanceTimerBadge(), SizedBox(width: 16)],
          ),
          body: (state.isLoading && state.students.isEmpty)
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeaderSection(context, state)),
                    _buildStudentsList(state),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                  ],
                ),
          // Correction ici : On passe les paramètres au constructeur
          bottomNavigationBar: AttendanceBottomBar(
            present: state.presentCount,
            absent: state.absentCount,
            late: state.lateCount,
            total: state.students.length,
            isSubmitting: state.isSubmitting,
            onValidate: state.isComplete 
                ? () => _confirmSubmit(context, state) 
                : null,
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, AttendanceState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AttendanceCourseSelector(state: state),
          const SizedBox(height: 16),
          // On passe les callbacks aux actions rapides
          AttendanceQuickActions(
            onMarkAllPresent: () => context.read<AttendanceBloc>().add(const AttendanceMarkAllPresent()),
            onMarkAllAbsent: () => _confirmAllAbsent(context),
            onInvert: () => _invertAll(context, state),
          ),
          const SizedBox(height: 16),
          _buildSimpleProgress(state),
        ],
      ),
    );
  }

  Widget _buildStudentsList(AttendanceState state) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final student = state.students[index];
          return AttendanceStudentTile(
            student: student,
            status: state.attendanceRecords[student.id] ?? AttendanceStatus.present,
            onToggle: () => context.read<AttendanceBloc>().add(AttendanceToggleStatus(studentId: student.id)),
          );
        },
        childCount: state.students.length,
      ),
    );
  }

  // Petit widget de progression conservé ici car très simple
  Widget _buildSimpleProgress(AttendanceState state) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progression', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${state.completionPercentage.toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: state.completionPercentage / 100,
          borderRadius: BorderRadius.circular(10),
          minHeight: 8,
        ),
      ],
    );
  }

  // --- LOGIQUE DE DIALOGUE (A GARDER DANS LA PAGE) ---

  void _confirmAllAbsent(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Marquer tout le monde absent ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Non')),
          TextButton(
            onPressed: () {
              context.read<AttendanceBloc>().add(const AttendanceMarkAllAbsent());
              Navigator.pop(ctx);
            }, 
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }

  void _invertAll(BuildContext context, AttendanceState state) {
    // Ta logique d'inversion d'état
    for (var student in state.students) {
       // ... logique toggle ...
    }
  }

  void _confirmSubmit(BuildContext context, AttendanceState state) {
    // Logique de validation finale
    context.read<AttendanceBloc>().add(AttendanceSubmitRequested(date: DateTime.now()));
  }
}