import 'package:educonnect/data/models/teacher_class_schedule_model.dart';
import 'package:educonnect/presentation/pages/teacher/widgets/day_section_header.dart';
import 'package:educonnect/presentation/pages/teacher/widgets/schedule_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/presentation/blocs/attendance/attendance_bloc.dart';
import '/presentation/blocs/attendance/attendance_event.dart';
import '/presentation/blocs/attendance/attendance_state.dart';

import '/presentation/pages/teacher/widgets/attendance_state_views.dart';


class AttendanceClassesPage extends StatefulWidget {
  const AttendanceClassesPage({super.key});

  @override
  State<AttendanceClassesPage> createState() => _AttendanceClassesPageState();
}

class _AttendanceClassesPageState extends State<AttendanceClassesPage> with SingleTickerProviderStateMixin {
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
    context.read<AttendanceBloc>().add(const AttendanceLoadClassesRequested(classId: '', courseId: ''));
    _animationController.forward();
  }

  @override
  void dispose() {
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
          if (state.error != null) AttendanceStateViews.showErrorSnackBar(context, state.error!, _loadClasses);
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
      title: const Text('Faire l\'appel', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
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
              ...items.map((item) => ScheduleCard(schedule: item)),
            ],
          );
        },
      ),
    );
  }

  // Garder cette logique de tri ici ou la déplacer dans un "Helper"
  Map<String, List<TeacherClassScheduleModel>> _groupAndSortByDay(List<TeacherClassScheduleModel> schedule) {
    final grouped = <String, List<TeacherClassScheduleModel>>{};
    for (final item in schedule) {
      grouped.putIfAbsent(item.dayName, () => []).add(item);
    }
    return grouped; // Logique de tri simplifiée pour l'exemple
  }

  String _getDayName(int day) => ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'][day];
}