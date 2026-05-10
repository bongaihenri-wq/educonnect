import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/auth_bloc/auth_bloc.dart' as auth;
import '../../../config/routes.dart';

class SuperAdminDashboardPage extends StatelessWidget {
  const SuperAdminDashboardPage({super.key});

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
                  Navigator.pushReplacementNamed(context, AppRoutes.schoolLogin);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(superAdmin),
                const SizedBox(height: 24),
                _buildGlobalStats(),
                const SizedBox(height: 24),
                _buildActionsGrid(context),
              ],
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
              child: Icon(Icons.admin_panel_settings, color: Color(0xFF6B4EFF), size: 30),
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
    return FutureBuilder<List<Map<String, dynamic>>>(
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

        final stats = snapshot.data ?? [];
        final totalSchools = stats.isNotEmpty ? stats[0]['total_schools'] ?? 0 : 0;
        final totalStudents = stats.isNotEmpty ? stats[0]['total_students'] ?? 0 : 0;
        final totalTeachers = stats.isNotEmpty ? stats[0]['total_teachers'] ?? 0 : 0;
        final totalParents = stats.isNotEmpty ? stats[0]['total_parents'] ?? 0 : 0;
        final activeSubscriptions = stats.isNotEmpty ? stats[0]['active_subscriptions'] ?? 0 : 0;
        final totalRevenue = stats.isNotEmpty ? stats[0]['total_revenue'] ?? 0 : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Globales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _StatCard(
                  icon: Icons.school,
                  label: 'Écoles',
                  value: totalSchools.toString(),
                  color: Colors.blue,
                ),
                _StatCard(
                  icon: Icons.people,
                  label: 'Élèves',
                  value: totalStudents.toString(),
                  color: Colors.green,
                ),
                _StatCard(
                  icon: Icons.person_outline,
                  label: 'Enseignants',
                  value: totalTeachers.toString(),
                  color: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.family_restroom,
                  label: 'Parents',
                  value: totalParents.toString(),
                  color: Colors.purple,
                ),
                _StatCard(
                  icon: Icons.payment,
                  label: 'Paiements',
                  value: activeSubscriptions.toString(),
                  color: Colors.teal,
                ),
                _StatCard(
                  icon: Icons.attach_money,
                  label: 'Revenus',
                  value: '${totalRevenue.toStringAsFixed(0)} XOF',
                  color: Colors.indigo,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchGlobalStats() async {
    try {
      final response = await Supabase.instance.client.rpc('get_super_admin_stats');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [{
        'total_schools': 0,
        'total_students': 0,
        'total_teachers': 0,
        'total_parents': 0,
        'active_subscriptions': 0,
        'total_revenue': 0,
      }];
    }
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
        icon: Icons.payment,
        label: 'Suivi Paiements',
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, AppRoutes.subscriptionTracking),
      ),
      _AdminAction(
        icon: Icons.people,
        label: 'Utilisateurs',
        color: Colors.orange,
        onTap: () {},
      ),
      _AdminAction(
        icon: Icons.bar_chart,
        label: 'Rapports',
        color: Colors.purple,
        onTap: () {},
      ),
      _AdminAction(
        icon: Icons.settings,
        label: 'Paramètres',
        color: Colors.grey,
        onTap: () {},
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

// ==================== WIDGETS ====================

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