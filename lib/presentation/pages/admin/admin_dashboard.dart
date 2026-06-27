import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme.dart';
import '../../../services/admin_stats_service.dart';
import '../../../services/period_service.dart';
import '../../../services/school_service.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_stats_grid.dart';
import 'widgets/school_stats_section.dart';
import 'widgets/admin_quick_actions.dart';
import 'widgets/period_selector.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminStatsService _statsService = AdminStatsService();
  final PeriodService _periodService = PeriodService();
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
  
  List<Map<String, dynamic>> _academicPeriods = [];
  Map<String, dynamic>? _selectedPeriod;
  int _daysRange = 30;
  bool _loadingPeriods = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // === CHARGER LES PÉRIODES DÈS LE DÉPART ===
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPeriodsFromState();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPeriodsFromState();
  }

  void _loadPeriodsFromState() {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated && state.schoolId != null) {
      final newSchoolId = state.schoolId;
      if (_schoolId != newSchoolId) {
        _schoolId = newSchoolId;
        _loadPeriods();
      }
    }
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

  Future<void> _loadPeriods() async {
    if (_schoolId == null) return;
    
    setState(() => _loadingPeriods = true);
    
    try {
      _academicPeriods = await _periodService.getAllPeriods(_schoolId!);
      final current = await _periodService.getCurrentPeriod(_schoolId!);
      
      if (mounted) {
        setState(() {
          _selectedPeriod = current;
          if (current != null) {
            final start = DateTime.parse(current['start_date'] as String);
            final end = DateTime.parse(current['end_date'] as String);
            _daysRange = end.difference(start).inDays;
          }
          _loadingPeriods = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement périodes: $e');
      if (mounted) setState(() => _loadingPeriods = false);
    }
  }

  void _onPeriodChanged(Map<String, dynamic>? period) {
    setState(() {
      _selectedPeriod = period;
      if (period != null) {
        final start = DateTime.parse(period['start_date'] as String);
        final end = DateTime.parse(period['end_date'] as String);
        _daysRange = end.difference(start).inDays;
      } else {
        _daysRange = 30;
      }
    });
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
                onPressed: () {
                  _loadStats();
                  _loadPeriods();
                },
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

                // 2. STATISTIQUES
                SliverToBoxAdapter(
                  child: AdminStatsGrid(stats: _stats, onRetry: _loadStats),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 3. SÉLECTEUR DE PÉRIODE
                if (_academicPeriods.isNotEmpty)
                  SliverToBoxAdapter(
                    child: PeriodSelector(
                      periods: _academicPeriods,
                      selectedPeriod: _selectedPeriod,
                      onPeriodChanged: _onPeriodChanged,
                    ),
                  )
                else if (_loadingPeriods)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 4. STATS ÉCOLE
                SliverToBoxAdapter(
                  child: SchoolStatsSection(
                    schoolId: _schoolId,
                    daysRange: _daysRange,
                    selectedPeriod: _selectedPeriod,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 5. PILOTAGE ÉTABLISSEMENT
                const SliverToBoxAdapter(
                  child: AdminQuickActions(),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }
}