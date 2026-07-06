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
import 'teacher_messages_page.dart';
import '../../widgets/empty_state_widget.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<CourseModel> _assignedCourses = [];
  List<Map<String, dynamic>> _adminMessages = [];
  List<Map<String, dynamic>> _parentMessages = [];
  bool _isLoading = true;
  bool _isLoadingMessages = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadMessages();
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
        final data = await context
            .read<TeacherService>()
            .getTeacherAssignments(teacherId);
        setState(() {
          _assignedCourses =
              data.map((json) => CourseModel.fromJson(json)).toList();
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

  Future<void> _loadMessages() async {
    final authState = context.read<AuthBloc>().state;
    final teacherId = _extractUserId(authState);
    final schoolId = _extractSchoolId(authState);

    if (teacherId.isEmpty || schoolId.isEmpty) {
      setState(() => _isLoadingMessages = false);
      return;
    }

    try {
      final adminMsgs = await TeacherService().getTeacherMessages(
        teacherId: teacherId,
        schoolId: schoolId,
      );

      final parentMsgs = await TeacherService().getParentMessages(
        teacherId: teacherId,
        limit: 50,
      );

      setState(() {
        _adminMessages = List<Map<String, dynamic>>.from(adminMsgs);
        _parentMessages = List<Map<String, dynamic>>.from(parentMsgs);
        _isLoadingMessages = false;
      });
    } catch (e) {
      debugPrint("Erreur messages: $e");
      setState(() => _isLoadingMessages = false);
    }
  }

  List<Map<String, dynamic>> _filterRecentMessages(
      List<Map<String, dynamic>> messages) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    return messages.where((msg) {
      final createdAt = DateTime.tryParse(msg['created_at'] as String? ?? '');
      return createdAt != null && createdAt.isAfter(yesterday);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is Unauthenticated,
      listener: (context, state) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      },
      child: Scaffold(
        backgroundColor: AppTheme.bisLight,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadDashboardData();
              await _loadMessages();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const DashboardHeader(),
                StatCardsRow(
                  teacherId: _extractUserId(context.read<AuthBloc>().state),
                  schoolId: _extractSchoolId(context.read<AuthBloc>().state),
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
                  teacherId: _extractUserId(context.read<AuthBloc>().state),
                  schoolId: _extractSchoolId(context.read<AuthBloc>().state),
                ),
                _isLoading
                    ? const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()))
                    : CourseListSection(courses: _assignedCourses),

                // ✅ CORRIGÉ : Section messages TOUJOURS affichée
                _buildMessagesSection(),

                const LogoutButton(),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesSection() {
    final authState = context.read<AuthBloc>().state;
    final teacherId = _extractUserId(authState);
    final schoolId = _extractSchoolId(authState);

    final recentAdminMessages = _filterRecentMessages(_adminMessages);
    final recentParentMessages = _filterRecentMessages(_parentMessages);
    final hasMessages =
        recentAdminMessages.isNotEmpty || recentParentMessages.isNotEmpty;
    final totalUnread = recentAdminMessages
            .where((m) => !(m['is_read'] as bool? ?? true))
            .length +
        recentParentMessages
            .where((m) => !(m['is_read'] as bool? ?? true))
            .length;

    // ✅ CORRIGÉ : On affiche TOUJOURS la section, même vide
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.message, color: AppTheme.violet, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.nightBlue,
                  ),
                ),
                const Spacer(),
                if (totalUnread > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalUnread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ✅ AJOUT : Empty state quand aucun message récent
          if (!hasMessages) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: EmptyStateWidget(
                icon: Icons.mark_email_unread_outlined,
                iconColor: Colors.grey,
                title: 'Aucun message récent',
                subtitle:
                    'Aucun message des dernières 24h.\nTous vos messages sont dans l\'onglet Messages.',
                actionLabel: 'Voir tous les messages',
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherMessagesPage(),
                  ),
                ),
              ),
            ),
          ],

          if (recentAdminMessages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.campaign, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Administration',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ...recentAdminMessages.take(3).map((msg) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildAdminMessageCard(msg),
                )),
          ],

          if (recentParentMessages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Parents',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ...recentParentMessages.take(3).map((msg) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildParentMessageCard(msg),
                )),
          ],

          // ✅ Le bouton "Voir tous les messages" reste visible même quand vide
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherMessagesPage(),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.violet.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Voir tous les messages',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.violet,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16, color: AppTheme.violet),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMessageCard(Map<String, dynamic> msg) {
    final isBroadcast = msg['is_broadcast'] == true;
    final isRead = msg['is_read'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isBroadcast
                      ? Colors.red.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isBroadcast ? '📢 ANNONCE' : '💬 Message',
                  style: TextStyle(
                    fontSize: 9,
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
                      color: Colors.red, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            msg['content'] ?? 'Sans contenu',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
              color: AppTheme.nightBlue,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'De: ${msg['sender_name'] ?? 'Admin'}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildParentMessageCard(Map<String, dynamic> msg) {
    final isRead = msg['is_read'] == true;
    final student = msg['students'] as Map<String, dynamic>?;
    final studentName = student != null
        ? '${student['first_name']} ${student['last_name']}'
        : 'Élève';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppTheme.violet.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isRead ? Colors.grey.shade200 : AppTheme.violet.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  msg['sender_name'] ?? 'Parent',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pour: $studentName',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            msg['content'] ?? '',
            style: TextStyle(
                fontSize: 12, color: AppTheme.nightBlue.withOpacity(0.8)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
