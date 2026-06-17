// lib/presentation/pages/super_admin/widgets/super_admin_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/presentation/blocs/auth_bloc/auth_bloc.dart';
import '/config/routes.dart';

class SuperAdminDrawer extends StatelessWidget {
  const SuperAdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4A44D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'EduConnect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Espace Super Admin',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: AppRoutes.superAdminDashboard,
          ),
          _buildItem(
            context,
            icon: Icons.school,
            title: 'Gestion des écoles',
            route: AppRoutes.schoolManagement,
          ),
          _buildItem(
            context,
            icon: Icons.payment,
            title: 'Suivi abonnements',
            route: AppRoutes.subscriptionDashboard,
          ),
          // ✅ NOUVEAU : Support Client
          _buildItem(
            context,
            icon: Icons.support_agent,
            title: 'Support Client',
            route: AppRoutes.supportDashboard,
            badge: 'Nouveau',
          ),
          _buildItem(
            context,
            icon: Icons.people,
            title: 'Gestion des rôles',
            route: AppRoutes.roleManagement,
          ),
          _buildItem(
            context,
            icon: Icons.upload_file,
            title: 'Import de données',
            route: AppRoutes.superAdminImport,
          ),
          const Divider(height: 32),
          _buildItem(
            context,
            icon: Icons.logout,
            title: 'Déconnexion',
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    String? badge,
    bool isLogout = false,
  }) {
    final Color color = isLogout ? Colors.red : const Color(0xFF6C63FF);

    return ListTile(
      leading: Icon(icon, color: color),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isLogout ? Colors.red : const Color(0xFF2D3142),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.pop(context); // Ferme le drawer
        if (isLogout) {
          context.read<AuthBloc>().add(const LogoutRequested());
        } else if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}