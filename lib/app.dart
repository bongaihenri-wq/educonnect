import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'data/repositories/attendance_repository.dart';
import 'data/repositories/class_repository.dart';
import 'data/repositories/course_repository.dart';
import 'data/repositories/student_repository.dart';
import 'presentation/blocs/auth_bloc/auth_bloc.dart' as auth;

class EduConnectApp extends StatelessWidget {
  const EduConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AttendanceRepository>(
          create: (context) => AttendanceRepository(supabase),
        ),
        RepositoryProvider<ClassRepository>(
          create: (context) => ClassRepository(supabase),
        ),
        RepositoryProvider<CourseRepository>(
          create: (context) => CourseRepository(supabase),
        ),
        RepositoryProvider<StudentRepository>(
          create: (context) => StudentRepository(supabase),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return BlocProvider(
            create: (context) => auth.AuthBloc()..add(auth.AppStarted()),
            child: MaterialApp(
              title: 'EduConnect',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.light,
              initialRoute: AppRoutes.schoolLogin,
              routes: AppRoutes.routes,
            ),
          );
        },
      ),
    );
  }
}