// lib/presentation/pages/teacher/teacher_dashboard.dart
import 'package:educonnect/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../services/teacher_service.dart';
import '../../../data/models/course_model.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/stat_cards_row.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/course_list_section.dart';
import 'widgets/teacher_comment_list_section.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<CourseModel> _assignedCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // ✅ AJOUTÉ : Extraction robuste de l'ID selon le type d'état
  String _extractUserId(AuthState state) {
    if (state is TeacherAuthenticated) return state.userId;
    if (state is Authenticated) return state.userId;
    return '';
  }

  // ✅ AJOUTÉ : Extraction robuste du schoolId selon le type d'état
  String _extractSchoolId(AuthState state) {
    if (state is TeacherAuthenticated) return state.schoolId;
    if (state is Authenticated) return state.schoolId;
    return '';
  }

  Future<void> _loadDashboardData() async {
    final authState = context.read<AuthBloc>().state;
    final teacherId = _extractUserId(authState);
    
    if (teacherId.isNotEmpty) {
      try {
        final data = await context.read<TeacherService>().getTeacherAssignments(teacherId);
        
        setState(() {
          _assignedCourses = data.map((json) => CourseModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        debugPrint("Erreur Dashboard: $e");
      }
    } else {
      setState(() => _isLoading = false);
      debugPrint("⚠️ TeacherDashboard: teacherId vide, impossible de charger les données");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final teacherId = _extractUserId(authState);   // ✅ Corrigé
    final schoolId = _extractSchoolId(authState);   // ✅ Corrigé
    
    print('🔍 TeacherDashboard - teacherId: "$teacherId", schoolId: "$schoolId"');

    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const DashboardHeader(),
              StatCardsRow(
                teacherId: teacherId,
                schoolId: schoolId,
              ),
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
                teacherId: teacherId,
                schoolId: schoolId,
              ),
              _isLoading 
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                : CourseListSection(courses: _assignedCourses),
              TeacherCommentListSection(teacherId: teacherId),
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
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      sliver: SliverToBoxAdapter(
        child: ElevatedButton.icon(
          onPressed: () {
            // ✅ SUPPRIMÉ : AppRoutes.logout(context) — cause le conflit
            context.read<AuthBloc>().add(const LogoutRequested());
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
