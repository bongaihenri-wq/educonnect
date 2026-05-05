// lib/presentation/pages/teacher/teacher_dashboard.dart
import 'package:educonnect/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../services/teacher_service.dart';
import '../../../data/models/course_model.dart'; // ✅ AJOUTÉ : Import CourseModel
import '../../blocs/auth_bloc/auth_bloc.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/stat_cards_row.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/course_list_section.dart';
import 'widgets/comment_list_section.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<CourseModel> _assignedCourses = []; // ✅ Maintenant reconnu
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authState = context.read<AuthBloc>().state;
    
    if (authState is Authenticated) {
      try {
        final teacherId = authState.userId;
        final data = await context.read<TeacherService>().getTeacherAssignments(teacherId);
        
        setState(() {
          _assignedCourses = data.map((json) => CourseModel.fromJson(json)).toList(); // ✅ Maintenant reconnu
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        debugPrint("Erreur Dashboard: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final teacherId = authState is Authenticated ? authState.userId : '';
    final schoolId = authState is Authenticated ? authState.schoolId : '';
    print('🔍 [1] Dashboard - teacherId: "$teacherId"');
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const DashboardHeader(),
              const StatCardsRow(),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Text(
                    'Actions rapides',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.nightBlue,
                    ),
                  ),
                ),
              ),
             QuickActionsGrid(
              teacherId: teacherId,     // ← AJOUTÉ
              schoolId: schoolId,      // ← AJOUTÉ
            ),
              _isLoading 
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                : CourseListSection(courses: _assignedCourses), 
              const CommentListSection(studentId: '',),
              const LogoutButton(),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    
    if (state is Authenticated) {
      print("🚀 User connecté : ${state.firstName} ${state.lastName}");
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      sliver: SliverToBoxAdapter(
        child: ElevatedButton.icon(
          onPressed: () {
            context.read<AuthBloc>().add(const LogoutRequested());
            AppRoutes.logout(context);
          },
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Se déconnecter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}