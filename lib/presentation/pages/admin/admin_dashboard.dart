// lib/presentation/pages/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme.dart';
import '../../../services/school_service.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String schoolId = 'f64a62bc-eef2-4ee6-aa5a-ac8bb0b70b50';
        String schoolCode = 'COL2024';
        String schoolName = 'Chargement...';
        String adminName = 'Administrateur';

        if (state is Authenticated) {
          schoolId = state.schoolId;
          adminName = '${state.firstName} ${state.lastName}'.trim();
          if (adminName.isEmpty) adminName = "Administrateur";
        }

        if (SchoolService.isConfigured) {
          schoolId = SchoolService.currentSchoolId ?? schoolId;
          schoolCode = SchoolService.currentSchoolCode ?? schoolCode;
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
                  child: _buildHeader(adminName, schoolName),
                ),

                // 2. INITIALISATION (SI BESOIN)
                if (!SchoolService.isConfigured)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildInitButton(),
                    ),
                  ),

                // 3. STATISTIQUES RAPIDES - FIXÉ
                SliverToBoxAdapter(child: _buildStatsGrid()),

                // 4. PILOTAGE ÉTABLISSEMENT - DÉFILEMENT HORIZONTAL
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilotage Établissement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.nightBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _quickAccessButton(context, Icons.people_alt, 'Classes & Élèves', Colors.blue, '/classes-students'),
                              const SizedBox(width: 12),
                              _quickAccessButton(context, Icons.calendar_today, 'Emploi du temps', Colors.teal, '/schedule'),
                              const SizedBox(width: 12),
                              _quickAccessButton(context, Icons.assignment, 'Devoirs', Colors.orange, '/homework'),
                              const SizedBox(width: 12),
                              _quickAccessButton(context, Icons.bar_chart, 'Notes', Colors.purple, '/grades'),
                              const SizedBox(width: 12),
                              _quickAccessButton(context, Icons.message, 'Messages', Colors.green, '/messages'),
                              const SizedBox(width: 12),
                              _quickAccessButton(context, Icons.settings, 'Paramètres', Colors.grey, '/settings'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),

                        _buildActionTile(
                          icon: Icons.upload_file_rounded,
                          label: 'Importation Massive (Excel/CSV)',
                          color: AppTheme.violet,
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _buildActionTile(
                          icon: Icons.analytics_outlined,
                          label: 'Rapports & Carnet de Notes',
                          color: Colors.pink,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String adminName, String schoolName) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.violet, AppTheme.violet.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $adminName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schoolName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.settings_suggest, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Configurer l\'école',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 16),
        ],
      ),
    );
  }

  // ✅ FIXÉ : childAspectRatio 1.3 au lieu de 1.5
  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _statCard('Classes', '3', Icons.class_, Colors.blue),
          _statCard('Élèves', '4', Icons.school, Colors.green),
          _statCard('Enseignants', '11', Icons.person, Colors.orange),
          _statCard('Parents', '4', Icons.family_restroom, Colors.purple),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _quickAccessButton(BuildContext context, IconData icon, String label, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}