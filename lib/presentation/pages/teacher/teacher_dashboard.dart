import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '/../presentation/blocs/auth_bloc/auth_bloc.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/stat_cards_row.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/course_list_section.dart';
import 'widgets/comment_list_section.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Logique pour rafraîchir les données si nécessaire
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const DashboardHeader(),
              
              const StatCardsRow(),
              
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
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
              
              const QuickActionsGrid(),
              
              const CourseListSection(),
              
              const CommentListSection(),
              
              const LogoutButton(),
              
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget interne pour le bouton de déconnexion
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      sliver: SliverToBoxAdapter(
        child: ElevatedButton.icon(
          onPressed: () {
            // Option A : Si ton événement s'appelle LogoutRequested (Standard)
            context.read<AuthBloc>().add(LogoutRequested());
            
            // Option B : Si ton événement s'appelle SignOut
            // context.read<AuthBloc>().add(SignOut());
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