// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'services/teacher_service.dart';
import 'data/repositories/attendance_repository.dart';
import 'data/repositories/class_repository.dart';
import 'data/repositories/student_repository.dart';
import 'data/repositories/course_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 MAIN - Début initialisation');

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Erreur lors du chargement du fichier .env: $e");
  }

  await initializeDateFormatting('fr_FR', null);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '', 
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  print('✅ Supabase initialisé');

  final supabase = Supabase.instance.client;

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TeacherService>(
          create: (context) => TeacherService(supabase: supabase),  // ✅ CORRIGÉ
        ),
        RepositoryProvider<AttendanceRepository>(
          create: (context) => AttendanceRepository(supabase),
        ),
        RepositoryProvider<ClassRepository>(
          create: (context) => ClassRepository(supabase),
        ),
        RepositoryProvider<StudentRepository>(
          create: (context) => StudentRepository(supabase),
        ),
        RepositoryProvider<CourseRepository>(
          create: (context) => CourseRepository(supabase),
        ),
      ],
      child: const EduConnectApp(),
    ),
  );
}