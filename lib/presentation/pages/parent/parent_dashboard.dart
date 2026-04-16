import 'package:educonnect/presentation/blocs/auth_bloc/auth_bloc.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import 'package:educonnect/presentation/pages/parent/child_detail_page.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header familial avec violet
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.violet.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Espace Parents 💜',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // NOUVEAU : ParentAuthenticated
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  if (state is ParentAuthenticated) {
                                    return Text(
                                      '${state.parentData['first_name']} ${state.parentData['last_name']}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }
                                  return const Text(
                                    'Espace Parent',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.white,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: AppTheme.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // NOUVEAU : École dynamique et lien parent-enfant
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        String schoolName = 'Mon École';
                        String childInfo = 'Enfant suivi';
                        
                        if (state is ParentAuthenticated) {
                          schoolName = state.schoolName;
                          final student = state.studentData;
                          childInfo = '${student['first_name']} ${student['last_name']} - ${student['classes']?['name'] ?? 'Classe inconnue'}';
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.school, color: AppTheme.white, size: 16),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      schoolName,
                                      style: TextStyle(
                                        color: AppTheme.white.withOpacity(0.95),
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.child_care, color: AppTheme.white, size: 16),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      childInfo,
                                      style: TextStyle(
                                        color: AppTheme.white.withOpacity(0.95),
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Carte enfant dynamique
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mon enfant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.nightBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // NOUVEAU : Carte enfant dynamique depuis le state
                  // Dans ParentDashboard, remplace la carte enfant par:

            BlocBuilder<auth.AuthBloc, auth.AuthState>(
               builder: (context, state) {
                  if (state is auth.ParentAuthenticated) {
                   return GestureDetector(
                   onTap: () {
          // Navigation vers détail enfant
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChildDetailPage(
                childData: state.studentData,
                parentData: state.parentData,
                relationship: state.relationship,
              ),
            ),
          );
        },
        child: _buildChildCard(
          name: state.studentData['first_name'],
          surname: state.studentData['last_name'],
          className: state.studentData['classes']?['name'] ?? 'Classe inconnue',
          school: state.schoolName,
          matricule: state.studentData['matricule'],
          relationship: state.relationship,
          color: AppTheme.violet,
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  },
),
                  ],
                ),
              ),
            ),

            // Alertes récentes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Alertes récentes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.nightBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.coral.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '2',
                            style: TextStyle(
                              color: AppTheme.coral,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildAlertCard(
                    type: 'absence',
                    childName: 'Emma',
                    message: 'Absence justifiée ce matin',
                    time: 'Aujourd\'hui',
                    icon: Icons.info_outline,
                    color: AppTheme.info,
                  ),
                  const SizedBox(height: 12),
                  _buildAlertCard(
                    type: 'note',
                    childName: 'Emma',
                    message: 'Nouvelle note : 16/20 en Français',
                    time: 'Hier',
                    icon: Icons.grade,
                    color: AppTheme.success,
                  ),
                ]),
              ),
            ),

            // Raccourcis
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
                child: const Text(
                  'Accès rapide',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.nightBlue,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                delegate: SliverChildListDelegate([
                  _buildQuickAccess(
                    icon: Icons.calendar_today,
                    label: 'Emploi du temps',
                    color: AppTheme.violetLight,
                  ),
                  _buildQuickAccess(
                    icon: Icons.show_chart,
                    label: 'Notes & moyennes',
                    color: AppTheme.violet,
                  ),
                  _buildQuickAccess(
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages profs',
                    color: AppTheme.teal,
                  ),
                  _buildQuickAccess(
                    icon: Icons.receipt_long,
                    label: 'Bulletins',
                    color: AppTheme.sunshine,
                  ),
                ]),
              ),
            ),

            // Bouton déconnexion (NOUVEAU)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutRequested());
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.rose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
          ],
        ),
      ),
    );
  }

  // NOUVEAU : Carte enfant avec données dynamiques
  Widget _buildChildCard({
    required String name,
    required String surname,
    required String className,
    required String school,
    required String matricule,
    required String relationship,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.bisDark, width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar avec initiales
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${name[0]}${surname[0]}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$name $surname',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.nightBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        className,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  school,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.nightBlueLight.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Matricule: $matricule • $relationship',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.nightBlueLight.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String type,
    required String childName,
    required String message,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.violetPale,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        childName,
                        style: const TextStyle(
                          color: AppTheme.violetDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.nightBlueLight.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.nightBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bisDark, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.nightBlue,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }
}
