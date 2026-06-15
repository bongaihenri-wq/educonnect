// lib/presentation/pages/parent/widgets/logout_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/presentation/blocs/auth_bloc/auth_bloc.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      sliver: SliverToBoxAdapter(
        child: ElevatedButton.icon(
          onPressed: () {
            // ✅ SEUL le Bloc gère la navigation — pas de Navigator ici
            context.read<AuthBloc>().add(const LogoutRequested());
          },
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text(
            'Se déconnecter',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}