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
                          String name = 'Enseignant';
                          if (state is auth.TeacherAuthenticated) {
                            name = '${state.userData['first_name']} ${state.userData['last_name']}';
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
        String schoolName = (state is auth.TeacherAuthenticated) ? state.schoolName : 'Mon École';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, color: AppTheme.white, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  schoolName,
                  style: const TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
