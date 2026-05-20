// lib/app.dart - VERSION FINALE AVEC PaymentPendingPage
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'config/routes.dart';
import 'presentation/blocs/auth_bloc/auth_bloc.dart';
import 'presentation/blocs/attendance/attendance_bloc.dart';
import 'presentation/pages/parent/subscription_expired_page.dart';
import 'presentation/pages/parent/payment_pending_page.dart'; // ✅ AJOUTÉ
import 'presentation/pages/parent/parent_dashboard.dart';
import 'presentation/pages/teacher/teacher_dashboard.dart';
import 'presentation/pages/admin/admin_dashboard.dart';
import 'presentation/pages/super_admin/super_admin_dashboard.dart';
import 'presentation/pages/school_login_page.dart';
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
          BlocProvider(create: (_) => AuthBloc(supabase)),
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
            primarySwatch: Colors.deepPurple,
            useMaterial3: true,
          ),
          initialRoute: AppRoutes.schoolLogin,
          routes: AppRoutes.routes,
          builder: (context, child) {
            return BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                print('🎯 BLOC LISTENER - State: ${state.runtimeType}');
                
                if (state is SubscriptionExpired) {
                  print('🎯 SubscriptionExpired → Navigation');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => SubscriptionExpiredPage(
                          parentId: state.parentId,
                          schoolId: state.schoolId,
                          expiresAt: state.expiresAt,
                          amount: state.amount,
                          currency: state.currency,
                          paymentPhoneNumber: state.paymentPhoneNumber,
                        ),
                      ),
                      (route) => false,
                    );
                  });
                } else if (state is PaymentSubmittedSuccessfully) {
                  // ✅ Seulement au login (pas depuis renouvellement)
                    print('🎯 PaymentSubmittedSuccessfully → PaymentPendingPage (login only)');
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                      navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(
                         builder: (_) => PaymentPendingPage(
                         reference: state.reference,
                         amount: state.amount,
                               ),
                         ),
                         (route) => false,
                          );
                    });
                } else if (state is ParentAuthenticated) {
                  print('🎯 ParentAuthenticated → Navigation');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const ParentDashboard()),
                      (route) => false,
                    );
                  });
                } else if (state is TeacherAuthenticated) {
                  print('🎯 TeacherAuthenticated → Navigation');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const TeacherDashboard()),
                      (route) => false,
                    );
                  });
                } else if (state is AdminAuthenticated) {
                  print('🎯 AdminAuthenticated → Navigation');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AdminDashboard()),
                      (route) => false,
                    );
                  });
                } else if (state is SuperAdminAuthenticated) {
                  print('🎯 SuperAdminAuthenticated → Navigation');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SuperAdminDashboardPage()),
                      (route) => false,
                    );
                  });
                } else if (state is Unauthenticated) {
                  print('🎯 Unauthenticated → Navigation vers Login');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SchoolLoginPage()),
                      (route) => false,
                    );
                  });
                }
              },
              child: child!,
            );
          },
        ),
      ),
    );
  }
}