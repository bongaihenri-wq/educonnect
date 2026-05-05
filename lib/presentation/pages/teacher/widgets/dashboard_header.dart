import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../blocs/auth_bloc/auth_bloc.dart' as auth;

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.violetGradient,
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
                        'Bonjour ! 👋',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      BlocBuilder<auth.AuthBloc, auth.AuthState>(
                        builder: (context, state) {
                          String name = 'Utilisateur';
                          // ✅ CORRIGÉ : Utiliser Authenticated (classe de base)
                          if (state is auth.Authenticated) {
                            name = '${state.firstName} ${state.lastName}'.trim();
                            if (name.isEmpty) {
                              // Déterminer le label par défaut selon le rôle
                              if (state is auth.TeacherAuthenticated) name = 'Enseignant';
                              else if (state is auth.AdminAuthenticated) name = 'Administrateur';
                              else if (state is auth.ParentAuthenticated) name = 'Parent';
                            }
                          }
                          return Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _buildNotificationIcon(),
              ],
            ),
            const SizedBox(height: 20),
            _buildSchoolBadge(),
            const SizedBox(height: 12),
            Text(
              'Prêt à faire briller vos élèves aujourd\'hui ?',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.white.withOpacity(0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.notifications_outlined, color: AppTheme.white),
    );
  }

  Widget _buildSchoolBadge() {
    return BlocBuilder<auth.AuthBloc, auth.AuthState>(
  builder: (context, state) {
    String name = 'Enseignant'; // ✅ Default "Enseignant" au lieu de "Utilisateur"
    if (state is auth.Authenticated) {
      name = '${state.firstName} ${state.lastName}'.trim();
      if (name.isEmpty) name = 'Enseignant';
    }
    return Text(
      name,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.white,
      ),
      overflow: TextOverflow.ellipsis,
    );
  },
);

  }
}

