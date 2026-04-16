import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import 'widgets/admin_header_card.dart';
import 'widgets/admin_stats_grid.dart';
import 'widgets/admin_action_tile.dart';
import '../../pages/admin/bulk_import_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Logique de scalabilité : On récupère les codes depuis le profil utilisateur
        String schoolId = '';
        String schoolCode = '';
        String schoolName = 'Mon École';
        String adminName = 'Administrateur';

        if (state is TeacherAuthenticated) {
          schoolId = state.userData['school_id'] ?? '';
          schoolCode = state.userData['school_code'] ?? '';
          schoolName = state.schoolName;
          adminName = '${state.userData['first_name']} ${state.userData['last_name']}';
        }

        return Scaffold(
          backgroundColor: AppTheme.bisLight,
          appBar: AppBar(
            title: const Text('Administration'),
            backgroundColor: AppTheme.violet,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // 1. Header avec Infos de l'école
                SliverToBoxAdapter(
                  child: AdminHeaderCard(
                    adminName: adminName,
                    schoolName: schoolName,
                  ),
                ),

                // 2. Statistiques
                const SliverToBoxAdapter(
                  child: AdminStatsGrid(),
                ),

                // 3. Actions (Import, etc.)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestion des données',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.nightBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AdminActionTile(
                          icon: Icons.upload_file,
                          label: 'Import CSV (Élèves, Enseignants, Planning)',
                          color: AppTheme.violet,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BulkImportPage(
                                  schoolId: schoolId,
                                  schoolCode: schoolCode,
                                  schoolYear: '2024-2025',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}