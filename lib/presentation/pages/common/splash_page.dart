
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import '/config/routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Déclencher la vérification de session
    context.read<AuthBloc>().add(AppStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('🔄 SplashPage - État: ${state.runtimeType}');
        
        if (state is Unauthenticated || state is AuthError) {
  print('⚠️ Non authentifié -> Login');
  Navigator.pushReplacementNamed(context, AppRoutes.schoolLogin);  // ✅ Utiliser la constante
  return;
}


        // ⭐ ADMIN
        if (state is AdminAuthenticated) {
          print('✅ Admin authentifié !');
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
          return;
        }
        
        // ⭐ ENSEIGNANT  
        if (state is TeacherAuthenticated) {
          print('✅ Enseignant authentifié !');
          Navigator.pushReplacementNamed(context, AppRoutes.teacherDashboard);
          return;
        }
        
        // ⭐ PARENT
        if (state is ParentAuthenticated) {
          print('✅ Parent authentifié !');
          Navigator.pushReplacementNamed(context, AppRoutes.parentDashboard);
          return;
        }
        
        // ⭐ NON AUTHENTIFIÉ ou ERREUR
        if (state is Unauthenticated || state is AuthError) {
          print('⚠️ Non authentifié -> Login');
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text((state as AuthError).message),
                backgroundColor: Colors.red,
              ),
            );
          }
          Navigator.pushReplacementNamed(context, AppRoutes.schoolLogin);
          return;
        }
        
        // AuthLoading : on reste sur le splash (rien à faire)
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
                child: Icon(
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
              // Indicateur de chargement
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 20),
                        Text(
                          'Vérification de la session...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}