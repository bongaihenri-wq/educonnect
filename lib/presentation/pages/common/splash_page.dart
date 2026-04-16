import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Vérifier la session au démarrage
    context.read<AuthBloc>().add(AppStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('🔄 SplashPage - État auth: ${state.runtimeType}');

        // NOUVEAU : Gestion des 3 états authentifiés séparés
        if (state is TeacherAuthenticated) {
          print('✅ Enseignant authentifié !');
          print('🏫 École: ${state.schoolName}');
          Navigator.pushReplacementNamed(context, '/teacher/dashboard');
          
        } else if (state is ParentAuthenticated) {
          print('✅ Parent authentifié !');
          print('🏫 École: ${state.schoolName}');
          print('👦 Élève: ${state.studentData['first_name']}');
          Navigator.pushReplacementNamed(context, '/parent/dashboard');
          
        } else if (state is Unauthenticated) {
          print('⚠️ Non authentifié -> Login');
          Navigator.pushReplacementNamed(context, '/login');
          
        } else if (state is AuthError) {
          print('❌ Erreur auth: ${state.message}');
          // Afficher l'erreur puis rediriger vers login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.rose,
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.violet,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school,
                  size: 60,
                  color: AppTheme.violet,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'EduConnect',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Suivi scolaire en temps réel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 60),
              // Animation de chargement
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                      if (state is AuthLoading) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Connexion en cours...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
