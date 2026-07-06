// lib/app.dart
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
import 'core/analytics/analytics_event.dart';
import 'core/analytics/analytics_tracker.dart';

class EduConnectApp extends StatefulWidget {
  const EduConnectApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<EduConnectApp> createState() => _EduConnectAppState();
}

class _EduConnectAppState extends State<EduConnectApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    analytics.flushImmediately();
    analytics.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // ✅ NE PAS tracker app_resumed comme app_launched
        // analytics.track(AnalyticsEvents.appResumed);
        break;
      case AppLifecycleState.paused:
        analytics.track(AnalyticsEvents.appPaused);
        analytics.flushImmediately();
        break;
      case AppLifecycleState.detached:
        analytics.track(AnalyticsEvents.appTerminated);
        analytics.flushImmediately();
        break;
      default:
        break;
    }
  }

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
          navigatorKey: EduConnectApp.navigatorKey,
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
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          home: const AuthStateRouter(),
          routes: AppRoutes.routes,
          navigatorObservers: [
            _AnalyticsNavigatorObserver(),
          ],
        ),
      ),
    );
  }
}

// ✅ CORRIGÉ : Observer utilise _getScreenName() partout
class _AnalyticsNavigatorObserver extends NavigatorObserver {
  String _getScreenName(Route route) {
    // 1. Utiliser settings.name si disponible (route nommée)
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      return route.settings.name!;
    }

    // 2. Ignorer les overlays (popup, menu, dialog)
    final type = route.runtimeType.toString();
    if (type.contains('Popup') ||
        type.contains('Dialog') ||
        type.contains('Modal') ||
        type.contains('BottomSheet')) {
      return '_overlay'; // Marqueur pour ignorer
    }

    // 3. Fallback : type de la route
    return type;
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    // ✅ CORRIGÉ : Utilise _getScreenName() au lieu de l'ancienne logique
    final screenName = _getScreenName(route);
    if (screenName != '_overlay') {
      analytics.trackScreen(screenName);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      // ✅ CORRIGÉ : Utilise _getScreenName()
      final screenName = _getScreenName(newRoute);
      if (screenName != '_overlay') {
        analytics.trackScreen(screenName);
      }
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      // ✅ CORRIGÉ : Utilise _getScreenName()
      final screenName = _getScreenName(previousRoute);
      if (screenName != '_overlay') {
        analytics.trackScreen(screenName);
      }
    }
  }
}
