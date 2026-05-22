// lib/presentation/pages/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme.dart';
import '../../../services/admin_stats_service.dart';
import '../../../services/school_service.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_stats_grid.dart';
import 'widgets/school_stats_section.dart';
import 'widgets/admin_quick_actions.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminStatsService _statsService = AdminStatsService();
  Map<String, dynamic> _stats = {
    'students': 0,
    'classes': 0,
    'teachers': 0,
    'parents': 0,
    'average_grade': '0.00',
    'loading': true,
    'error': null,
  };
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      _schoolId = state.schoolId;
      if (_schoolId != null) {
        final stats = await _statsService.getSchoolStats(_schoolId!);
        if (mounted) {
          setState(() => _stats = stats);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String schoolId = '';
        String schoolName = 'Chargement...';
        String adminName = 'Administrateur';

        if (state is Authenticated) {
          schoolId = state.schoolId ?? '';
          _schoolId = schoolId;
          adminName = '${state.firstName} ${state.lastName}'.trim();
          if (adminName.isEmpty) adminName = "Administrateur";
        }

        if (SchoolService.isConfigured) {
          schoolName = SchoolService.currentSchoolName ?? schoolName;
        }

        return Scaffold(
          backgroundColor: AppTheme.bisLight,
          appBar: AppBar(
            elevation: 0,
            title: const Text('Hub Administration'),
            backgroundColor: AppTheme.violet,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Actualiser',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadStats,
              ),
              IconButton(
                tooltip: 'Déconnexion',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () {
                  context.read<AuthBloc>().add(const LogoutRequested());
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. ENTÊTE
                SliverToBoxAdapter(
                  child: AdminHeader(adminName: adminName, schoolName: schoolName),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 2. STATISTIQUES RÉELLES (cartes compactes)
                SliverToBoxAdapter(
                  child: AdminStatsGrid(stats: _stats, onRetry: _loadStats),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 3. STATS ÉCOLE (graphiques cumulés)
                SliverToBoxAdapter(
                  child: SchoolStatsSection(schoolId: _schoolId),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 4. PILOTAGE ÉTABLISSEMENT
                const SliverToBoxAdapter(
                  child: AdminQuickActions(),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        );
      },
    );
  }
}