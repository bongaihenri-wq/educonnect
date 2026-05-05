// lib/presentation/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/dashboard/dashboard_bloc.dart';
import '../blocs/dashboard/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DashboardLoaded) {
            final stats = state.stats;
            
            return RefreshIndicator(
              onRefresh: () async {
                // Logique de rafraîchissement si nécessaire
              },
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      delegate: SliverChildListDelegate([
                        StatCard(
                          title: "Élèves",
                          value: "${stats.totalStudents}",
                          icon: Icons.people_alt_rounded,
                          color: Colors.blue,
                        ),
                        StatCard(
                          title: "Enseignants",
                          value: "${stats.totalTeachers}",
                          icon: Icons.person,
                          color: Colors.green,
                        ),
                        StatCard(
                          title: "Classes",
                          value: "${stats.totalClasses}",
                          icon: Icons.meeting_room_rounded,
                          color: Colors.orange,
                        ),
                        StatCard(
                          title: "Absences Jour",
                          value: "${stats.todayAbsences}",
                          icon: Icons.warning_amber_rounded,
                          color: Colors.red,
                        ),
                      ]),
                    ),
                  ),
                  _buildRecentActivityHeader(),
                  _buildActivityList(), // À implémenter avec tes données réelles
                ],
              ),
            );
          }

          if (state is DashboardError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
  // --- AJOUTE CES MÉTHODES ICI ---

  Widget _buildRecentActivityHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          "Activités Récentes",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    // Pour l'instant, on affiche une liste statique ou un message
    // On pourra la connecter au repository plus tard
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F3F4),
                child: Icon(Icons.notifications_none, color: Colors.blue),
              ),
              title: Text("Activité ${index + 1}"),
              subtitle: const Text("Mise à jour du système scolaire"),
              trailing: Text(
                "10:30",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          );
        },
        childCount: 3, // Nombre d'éléments fictifs
      ),
    );
  }

  Widget _buildAppBar() {
    return const SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        title: Text(
          "Tableau de Bord",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
  
  // ... Autres widgets (Header activité, liste)
}