// lib/app.dart - VERSION CORRIGÉE AVEC NAVIGATION DÉCLARATIVE
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'config/routes.dart';
import 'config/theme.dart';
import 'presentation/blocs/auth_bloc/auth_bloc.dart';
import 'presentation/blocs/attendance/attendance_bloc.dart';
import 'presentation/pages/auth_state_router.dart';
import 'data/repositories/attendance_repository.dart';
import 'data/repositories/class_repository.dart';
import 'data/repositories/student_repository.dart';
import 'data/repositories/course_repository.dart';
import 'services/teacher_service.dart';

class EduConnectApp extends StatelessWidget {
  const EduConnectApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AttendanceRepository(supabase)),
        RepositoryProvider(create: (_) => ClassRepository(supabase)),
        RepositoryProvider(create: (_) => StudentRepository(supabase)),
        RepositoryProvider(create: (_) => CourseRepository(supabase)),
        RepositoryProvider(create: (_) => TeacherService(supabase: supabase)),
      ],
      child: MultiBlocProvider(
        providers: [
          // ✅ CORRIGÉ : Ajout de AppStarted au démarrage
          BlocProvider(
            create: (_) => AuthBloc(supabase)..add(const AppStarted()),
          ),
          BlocProvider(
            create: (context) => AttendanceBloc(
              attendanceRepository: context.read<AttendanceRepository>(),
              classRepository: context.read<ClassRepository>(),
              studentRepository: context.read<StudentRepository>(),
              courseRepository: context.read<CourseRepository>(),
              teacherService: context.read<TeacherService>(),
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'EduConnect',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppTheme.violet,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.violet,
              primary: AppTheme.violet,
              secondary: AppTheme.teal,
              surface: AppTheme.bisLight,
              error: Colors.redAccent,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
            appBarTheme: AppBarTheme(
              backgroundColor: AppTheme.violet,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.violet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: AppTheme.white,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.bisDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.bisDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.violet, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
          ],
          // ✅ SUPPRIMÉ : initialRoute (remplacé par home)
          // ✅ SUPPRIMÉ : BlocListener de navigation dans builder
          home: const AuthStateRouter(), // ✅ AJOUTÉ : Navigation déclarative
          routes: AppRoutes.routes,
        ),
      ),
    );
  }
}