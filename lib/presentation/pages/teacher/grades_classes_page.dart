// lib/presentation/pages/teacher/grades_classes_page.dart
import 'package:educonnect/data/models/class_model.dart';
import 'package:educonnect/data/models/course_model.dart';
import 'package:educonnect/presentation/pages/teacher/grades_entry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:educonnect/data/models/teacher_class_schedule_model.dart';
import 'package:educonnect/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:educonnect/presentation/pages/teacher/widgets/day_section_header.dart';
import '/presentation/blocs/attendance/attendance_bloc.dart';
import '/presentation/blocs/attendance/attendance_event.dart';
import '/presentation/blocs/attendance/attendance_state.dart';
import '/config/routes.dart';

// ✅ Widgets locaux simples
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class EmptyView extends StatelessWidget {
  final VoidCallback onRetry;
  const EmptyView({super.key, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Aucune classe trouvée'),
        ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    ),
  );
}

class GradesClassesPage extends StatefulWidget {
  const GradesClassesPage({super.key});

  @override
  State<GradesClassesPage> createState() => _GradesClassesPageState();
}

class _GradesClassesPageState extends State<GradesClassesPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final int _currentDay = DateTime.now().weekday;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadClasses();
  }

  void _initAnimation() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
  }

  void _loadClasses() {
    // ✅ CORRIGÉ : Récupérer teacherId et schoolId depuis AuthBloc
    final authState = context.read<AuthBloc>().state;
    String teacherId = '';
    String schoolId = '';
    
    if (authState is Authenticated) {
      teacherId = authState.userId;
      schoolId = authState.schoolId;
    }
    
    context.read<AttendanceBloc>().add(AttendanceLoadClassesRequested(
      teacherId: teacherId,
      schoolId: schoolId,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    print('🔥 GradesEntryPage.dispose()');
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Réessayer',
                  onPressed: _loadClasses,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.teacherSchedule.isEmpty) return const LoadingView();
          if (state.teacherSchedule.isEmpty) return EmptyView(onRetry: _loadClasses);
          
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildScheduleList(state.teacherSchedule),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text('Saisie des Notes', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6)), onPressed: _loadClasses),
      ],
    );
  }

  Widget _buildScheduleList(List<TeacherClassScheduleModel> schedule) {
    final grouped = _groupAndSortByDay(schedule);
    return RefreshIndicator(
      onRefresh: () async => _loadClasses(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final entry = grouped.entries.elementAt(index);
          final dayName = entry.key;
          final items = entry.value;
          final isToday = dayName.toLowerCase() == _getDayName(_currentDay).toLowerCase();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DaySectionHeader(dayName: entry.key, isToday: isToday, isFirst: index == 0),
              ...items.map((item) => _GradeScheduleCard(schedule: item)),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<TeacherClassScheduleModel>> _groupAndSortByDay(List<TeacherClassScheduleModel> schedule) {
    final grouped = <String, List<TeacherClassScheduleModel>>{};
    for (final item in schedule) {
      grouped.putIfAbsent(item.dayName, () => []).add(item);
    }
    return grouped;
  }

  String _getDayName(int day) => ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'][day];
}

class _GradeScheduleCard extends StatelessWidget {
  final TeacherClassScheduleModel schedule;
  const _GradeScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToGrades(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildTimeBadge(),
              const SizedBox(width: 16),
              Expanded(child: _buildInfo()),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBadge() {
    return Container(
      width: 55, height: 55,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(Icons.grade, color: Colors.orange.shade800, size: 24),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(schedule.className, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(schedule.subjectName, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 4),
        Text('${schedule.startTime} - ${schedule.endTime}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

void _navigateToGrades(BuildContext context) {
  final state = context.read<AttendanceBloc>().state;
  
  final classModel = state.classes.firstWhere(
    (c) => c.id == schedule.classId,
    orElse: () => ClassModel(
      id: schedule.classId,
      name: schedule.className,
      levelId: 'default',
      schoolId: state.schoolId,
    ),
  );
  
  final currentDay = DateTime.now().weekday;
  final courseModel = CourseModel(
    id: schedule.subjectId ?? '',
    name: schedule.subjectName,
    classId: schedule.classId,
    teacherId: '',
    dayOfWeek: currentDay,
    startTime: schedule.startTime,
    endTime: schedule.endTime,
    schoolId: state.schoolId, subjectId: schedule.subjectId,
  );
  
  context.read<AttendanceBloc>().add(AttendanceClassSelected(
    classModel,
    schoolId: state.schoolId,
    currentCourse: courseModel,
  ));
  
  // ✅ NAVIGUER avec BlocProvider.value
  final attendanceBloc = context.read<AttendanceBloc>();
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BlocProvider.value(
        value: attendanceBloc,
        child: GradesEntryPage(
          classId: schedule.classId,
          className: schedule.className,
          subjectId: schedule.subjectId,
          subjectName: schedule.subjectName,
          scheduleId: schedule.scheduleId,
        ),
      ),
    ),
  );
}
}
