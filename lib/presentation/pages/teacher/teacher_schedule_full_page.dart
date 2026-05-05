// lib/presentation/pages/teacher/teacher_schedule_full_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../presentation/blocs/auth_bloc/auth_bloc.dart' as auth;
import '../../../services/teacher_service.dart';

class TeacherScheduleFullPage extends StatefulWidget {
  const TeacherScheduleFullPage({super.key});

  @override
  State<TeacherScheduleFullPage> createState() => _TeacherScheduleFullPageState();
}

class _TeacherScheduleFullPageState extends State<TeacherScheduleFullPage> {
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final authState = context.read<auth.AuthBloc>().state;
    if (authState is auth.Authenticated) {
      try {
        final data = await context.read<TeacherService>().getTeacherSchedule(
          teacherId: authState.userId,
          schoolId: authState.schoolId,
        );
        setState(() {
          _schedule = data;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mon Emploi du Temps',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildScheduleView(),
    );
  }

  Widget _buildScheduleView() {
    final grouped = _groupByDay(_schedule);
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final dayName = days[index];
        final dayCourses = grouped[dayName] ?? [];
        final isToday = DateTime.now().weekday == index + 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header jour
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isToday ? Colors.green : AppTheme.violet,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.green.shade800 : AppTheme.nightBlue,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Aujourd\'hui',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Cours du jour
            if (dayCourses.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 16),
                child: Text(
                  'Pas de cours',
                  style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                ),
              )
            else
              ...dayCourses.map((course) => _buildCourseCard(course)),

            const Divider(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bisDark),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.violet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.class_, color: AppTheme.violet),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['subjects']?['name'] ?? 'Matière',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '${course['classes']?['name'] ?? ''} • ${course['room'] ?? 'Salle non assignée'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  '${course['start_time']} - ${course['end_time']}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDay(List<Map<String, dynamic>> schedule) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in schedule) {
      final dayIndex = item['day_of_week'] ?? 1;
      final dayName = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'][dayIndex];
      grouped.putIfAbsent(dayName, () => []).add(item);
    }
    return grouped;
  }
}
