// lib/presentation/pages/super_admin/super_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/auth_bloc/auth_bloc.dart' as auth;
import '../../../config/routes.dart';
import '../../../services/subscription_service.dart';
import 'analytics_dashboard_page.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  int _pendingPaymentsCount = 0;
  bool _isLoadingPending = true;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final service = SubscriptionService(Supabase.instance.client);
      final pending = await service.getPendingPayments();
      setState(() {
        _pendingPaymentsCount = pending.length;
        _isLoadingPending = false;
      });
    } catch (e) {
      setState(() => _isLoadingPending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<auth.AuthBloc, auth.AuthState>(
      builder: (context, state) {
        if (state is! auth.SuperAdminAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final superAdmin = state;

        return Scaffold(
          appBar: AppBar(
            title: const Text('EduConnect — Super Admin'),
            backgroundColor: const Color(0xFF6B4EFF),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<auth.AuthBloc>().add(auth.LogoutRequested());
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.schoolLogin);
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadPendingCount,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(superAdmin),
                  const SizedBox(height: 24),
                  _buildGlobalStats(),
                  const SizedBox(height: 24),
                  _buildActionsGrid(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(auth.SuperAdminAuthenticated admin) {
    return Card(
      color: const Color(0xFF6B4EFF),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings,
                  color: Color(0xFF6B4EFF), size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${admin.firstName} ${admin.lastName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Super Administrateur',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    admin.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchGlobalStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final totalSchools = stats['total_schools'] ?? 0;
        final totalStudents = stats['total_students'] ?? 0;
        final totalTeachers = stats['total_teachers'] ?? 0;
        final totalParents = stats['total_parents'] ?? 0;
        final totalPayments = stats['total_payments'] ?? 0;
        final totalRevenue = stats['total_revenue'] ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Globales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 44) / 2,
                  child: _StatCard(
                    icon: Icons.school,
                    label: 'Écoles',
                    value: totalSchools.toString(),
                    color: Colors.blue,
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 44) / 2,
                  child: _StatCard(
                    icon: Icons.people,
                    label: 'Élèves',
                    value: totalStudents.toString(),
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 44) / 2,
                  child: _StatCard(
                    icon: Icons.person_outline,
                    label: 'Enseignants',
                    value: totalTeachers.toString(),
                    color: Colors.orange,
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 44) / 2,
                  child: _StatCard(
                    icon: Icons.family_restroom,
                    label: 'Parents',
                    value: totalParents.toString(),
                    color: Colors.purple,
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 44) / 2,
                  child: _StatCard(
                    icon: Icons.payment,
                    label: 'Paiements',
                    value: totalPayments.toString(),
                    color: Colors.teal,
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 44) / 2,
                  child: _StatCard(
                    icon: Icons.attach_money,
                    label: 'Revenus',
                    value: '${_formatNumber(totalRevenue)} XOF',
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchGlobalStats() async {
    try {
      final supabase = Supabase.instance.client;

      final schoolsResponse = await supabase.from('schools').select('id');
      final totalSchools = (schoolsResponse as List).length;

      final studentsResponse = await supabase.from('students').select('id');
      final totalStudents = (studentsResponse as List).length;

      final teachersResponse =
          await supabase.from('app_users').select('id').eq('role', 'teacher');
      final totalTeachers = (teachersResponse as List).length;

      final parentsResponse =
          await supabase.from('app_users').select('id').eq('role', 'parent');
      final totalParents = (parentsResponse as List).length;

      final paymentsResponse = await supabase
          .from('payment_transactions')
          .select('id')
          .eq('status', 'verified');
      final totalPayments = (paymentsResponse as List).length;

      final revenueResponse = await supabase
          .from('payment_transactions')
          .select('amount')
          .eq('status', 'verified');
      final totalRevenue = (revenueResponse as List).fold<int>(
          0, (sum, item) => sum + ((item['amount'] as num?)?.toInt() ?? 0));

      return {
        'total_schools': totalSchools,
        'total_students': totalStudents,
        'total_teachers': totalTeachers,
        'total_parents': totalParents,
        'total_payments': totalPayments,
        'total_revenue': totalRevenue,
      };
    } catch (e) {
      print('❌ Erreur _fetchGlobalStats: $e');
      return {
        'total_schools': 0,
        'total_students': 0,
        'total_teachers': 0,
        'total_parents': 0,
        'total_payments': 0,
        'total_revenue': 0,
      };
    }
  }

  String _formatNumber(dynamic n) {
    if (n == null) return '0';
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  Widget _buildActionsGrid(BuildContext context) {
    final actions = [
      _AdminAction(
        icon: Icons.school,
        label: 'Gestion des Écoles',
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, AppRoutes.schoolManagement),
      ),
      _AdminAction(
        icon: Icons.add_business,
        label: 'Créer École + Importer',
        color: Colors.deepPurple,
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.schoolManagement,
          arguments: {'openImport': true},
        ),
      ),
      _AdminAction(
        icon: Icons.monetization_on,
        label: '💰 Suivi Abonnements',
        color: Colors.green,
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.subscriptionDashboard),
      ),
      _AdminAction(
        icon: Icons.support_agent,
        label: 'Support Client',
        color: Colors.orange,
        onTap: () => Navigator.pushNamed(context, AppRoutes.supportDashboard),
      ),
      _AdminAction(
        icon: Icons.calendar_month,
        label: 'Années Scolaires',
        color: const Color(0xFF6C63FF),
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.schoolYearManagement),
      ),
      _AdminAction(
        icon: Icons.analytics,
        label: 'Rapports',
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AnalyticsDashboardPage(),
            ),
          );
        },
      ),
      _AdminAction(
        icon: Icons.trending_up,
        label: 'Commercial',
        color: Colors.teal,
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.commercialDashboard),
      ),
      _AdminAction(
        icon: Icons.manage_accounts,
        label: 'Gestion des Rôles',
        color: Colors.indigo,
        onTap: () => Navigator.pushNamed(context, AppRoutes.roleManagement),
      ),
      _AdminAction(
        icon: Icons.date_range,
        label: 'Trimestres Écoles',
        color: Colors.pink,
        onTap: () => Navigator.pushNamed(context, AppRoutes.schoolManagement),
      ),
      _AdminAction(
        icon: Icons.key,
        label: 'Identifiants',
        color: Colors.amber,
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.superAdminCredentials),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: actions.map((a) => _ActionCard(action: a)).toList(),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _AdminAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  final _AdminAction action;

  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.color, size: 32),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
