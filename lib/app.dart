// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/routes.dart';
import 'presentation/blocs/auth_bloc/auth_bloc.dart';
import 'presentation/blocs/attendance/attendance_bloc.dart';
import 'data/repositories/attendance_repository.dart';
import 'data/repositories/class_repository.dart';
import 'data/repositories/student_repository.dart';
import 'data/repositories/course_repository.dart';
import 'services/teacher_service.dart';

class EduConnectApp extends StatelessWidget {
  const EduConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AttendanceRepository(supabase)),
        RepositoryProvider(create: (_) => ClassRepository(supabase)),
        RepositoryProvider(create: (_) => StudentRepository(supabase)),
        RepositoryProvider(create: (_) => CourseRepository(supabase)),
        RepositoryProvider(create: (_) => TeacherService(supabase: supabase)),  // ✅ CORRIGÉ
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
          title: 'EduConnect',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            useMaterial3: true,
          ),
          initialRoute: AppRoutes.schoolLogin,
          routes: AppRoutes.routes,
        ),
      ),
    );
  }
}