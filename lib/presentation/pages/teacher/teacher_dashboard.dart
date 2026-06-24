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
  List<Map<String, dynamic>> _adminMessages = [];
  bool _isLoading = true;
  bool _isLoadingMessages = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadAdminMessages();
  }

  String _extractUserId(AuthState state) {
    if (state is TeacherAuthenticated) return state.userId;
    if (state is Authenticated) return state.userId;
    return '';
  }

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
    }
  }

  Future<void> _loadAdminMessages() async {
    final authState = context.read<AuthBloc>().state;
    final teacherId = _extractUserId(authState);
    final schoolId = _extractSchoolId(authState);

    if (teacherId.isEmpty || schoolId.isEmpty) {
      setState(() => _isLoadingMessages = false);
      return;
    }

    try {
      final messages = await TeacherService().getTeacherMessages(
        teacherId: teacherId,
        schoolId: schoolId,
      );
      setState(() {
        _adminMessages = messages;
        _isLoadingMessages = false;
      });
    } catch (e) {
      debugPrint("Erreur messages admin: $e");
      setState(() => _isLoadingMessages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final teacherId = _extractUserId(authState);
    final schoolId = _extractSchoolId(authState);

    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadDashboardData();
            await _loadAdminMessages();
          },
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
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
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
              if (_adminMessages.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      children: [
                        Icon(Icons.campaign, color: Colors.orange, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Messages de l\'administration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.nightBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final msg = _adminMessages[index];
                        final isBroadcast = msg['is_broadcast'] == true;
                        final isRead = msg['is_read'] == true;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : Colors.orange.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead ? AppTheme.bisDark : Colors.orange.withOpacity(0.3),
                              width: isRead ? 1 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isBroadcast 
                                          ? Colors.red.withOpacity(0.1) 
                                          : Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isBroadcast ? '📢 ANNONCE' : '💬 Message',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isBroadcast ? Colors.red : Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                msg['content'] ?? 'Sans contenu',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                  color: AppTheme.nightBlue,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'De: ${msg['sender_name'] ?? 'Admin'} • ${msg['sender_role'] ?? 'Administration'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: _adminMessages.length > 5 ? 5 : _adminMessages.length,
                    ),
                  ),
                ),
              ],
              _isLoading 
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                : CourseListSection(courses: _assignedCourses),
              TeacherCommentListSection(teacherId: teacherId),
              const LogoutButton(),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
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