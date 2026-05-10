// lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pages
import '../presentation/pages/school_login_page.dart';
import '../presentation/pages/admin/admin_dashboard.dart';
import '../presentation/pages/admin/bulk_import_page.dart';
import '../presentation/pages/admin/schedule_page.dart';
import '../presentation/pages/parent/parent_dashboard.dart';
import '../presentation/pages/teacher/teacher_dashboard.dart';
import '../presentation/pages/teacher/attendance/attendance_classes_page.dart';
import '../presentation/pages/admin/classes_students_page.dart';
import '../presentation/pages/teacher/comments_entry_page.dart';
import '../presentation/pages/teacher/comments_classes_page.dart';
import '../presentation/pages/teacher/grades_entry_page.dart';
import '../presentation/pages/teacher/grades_classes_page.dart';
import '../presentation/pages/teacher/teacher_schedule_full_page.dart';
import '../presentation/pages/teacher/teacher_reports_page.dart';

// Super Admin pages
import '../presentation/pages/super_admin/super_admin_dashboard.dart';
import '../presentation/pages/super_admin/school_management/school_management_page.dart'; // ⭐ CORRIGÉ
import '../presentation/pages/super_admin/school_management/school_detail_page.dart'; // ⭐ AJOUTÉ
import '../presentation/pages/super_admin/subscription_tracking_page.dart';
import '../presentation/pages/super_admin/import_report_page.dart';
import '../presentation/pages/super_admin/import_preview_page.dart';

// BLoCs
import '../presentation/blocs/attendance/attendance_page.dart';
import '../presentation/blocs/attendance/attendance_bloc.dart';
import '../presentation/blocs/attendance/attendance_event.dart';
import '../presentation/blocs/auth_bloc/auth_bloc.dart' as auth;

// Repositories & Services
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/class_repository.dart';
import '../data/repositories/student_repository.dart';
import '../data/repositories/course_repository.dart';
import '../services/teacher_service.dart';
import '../services/bulk_import_service.dart';

class AppRoutes {
  static const String schoolLogin = '/login';
  static const String teacherDashboard = '/teacher/dashboard';
  static const String parentDashboard = '/parent/dashboard';
  static const String adminDashboard = '/admin/dashboard';
  
  // Super Admin routes
  static const String superAdminDashboard = '/super-admin/dashboard';
  static const String schoolManagement = '/super-admin/schools';
  static const String schoolDetail = '/super-admin/school-detail'; // ⭐ AJOUTÉ
  static const String subscriptionTracking = '/super-admin/subscriptions';
  static const String importReport = '/import-report';
  
  static const String teacherAttendanceClasses = '/teacher/attendance/classes';
  static const String teacherAttendance = '/teacher/attendance';
  static const String adminBulkImport = '/admin/import';
  static const String schedulePage = '/schedule_page';
  static const String classesStudents = '/classes_students';
  static const String teacherGradesClasses = '/teacher/grades-classes';
  static const String teacherGradesEntry = '/teacher/grades-entry';
  static const String teacherCommentsClasses = '/teacher/comments-classes';
  static const String teacherCommentsEntry = '/teacher/comments-entry';
  static const String teacherScheduleFull = '/teacher/schedule-full';
  static const String teacherReports = '/teacher/reports';

  static Map<String, WidgetBuilder> get routes => {
    schoolLogin: (context) => const SchoolLoginPage(),
    teacherDashboard: (context) => const TeacherDashboard(),
    parentDashboard: (context) => const ParentDashboard(),
    adminDashboard: (context) => const AdminDashboard(),
    
    // Super Admin routes
    superAdminDashboard: (context) => const SuperAdminDashboardPage(),
    schoolManagement: (context) => const SchoolManagementPage(),
    schoolDetail: (context) { // ⭐ AJOUTÉ
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SchoolDetailPage(school: args?['school'] ?? {});
    },
    subscriptionTracking: (context) => const SubscriptionTrackingPage(),
    
    teacherScheduleFull: (context) => const TeacherScheduleFullPage(),
  
    teacherReports: (context) => const Scaffold(
      body: Center(child: Text('Utiliser le bouton du dashboard')),
    ),
    
    teacherAttendanceClasses: (context) {
      final authState = context.read<auth.AuthBloc>().state;
      final teacherId = authState is auth.Authenticated ? authState.userId : '';
      final schoolId = authState is auth.Authenticated ? authState.schoolId : '';
      
      return BlocProvider(
        create: (_) => _createAttendanceBloc(context)..add(
          AttendanceLoadClassesRequested(
            teacherId: teacherId,
            schoolId: schoolId,
          ),
        ),
        child: const AttendanceClassesPage(),
      );
    },
    
    teacherAttendance: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return AttendancePage(
        classId: args?['classId'] ?? '',
        className: args?['className'] ?? 'Classe',
        subjectId: args?['subjectId'],
        subjectName: args?['subjectName'],
      );
    },
    
    adminBulkImport: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return BulkImportPage(
        schoolId: args?['schoolId'] ?? '',
        schoolCode: args?['schoolCode'] ?? '',
        schoolYear: args?['schoolYear'] ?? '2024-2025',
      );
    },
    
    schedulePage: (context) => const SchedulePage(),
    classesStudents: (context) => const ClassesStudentsPage(),
    
    teacherGradesClasses: (context) {
      final authState = context.read<auth.AuthBloc>().state;
      final teacherId = authState is auth.Authenticated ? authState.userId : '';
      final schoolId = authState is auth.Authenticated ? authState.schoolId : '';
      
      return BlocProvider(
        create: (_) => _createAttendanceBloc(context)..add(
          AttendanceLoadClassesRequested(
            teacherId: teacherId,
            schoolId: schoolId,
          ),
        ),
        child: const GradesClassesPage(),
      );
    },
    
    teacherGradesEntry: (context) => const GradesEntryPage(classId: '', className: '',),
    
    teacherCommentsClasses: (context) {
      final authState = context.read<auth.AuthBloc>().state;
      final teacherId = authState is auth.Authenticated ? authState.userId : '';
      final schoolId = authState is auth.Authenticated ? authState.schoolId : '';
      
      return BlocProvider(
        create: (_) => _createAttendanceBloc(context)..add(
          AttendanceLoadClassesRequested(
            teacherId: teacherId,
            schoolId: schoolId,
          ),
        ),
        child: const CommentsClassesPage(),
      );
    },
    
    teacherCommentsEntry: (context) => const CommentsEntryPage(classId: '', className: '',),
    
    importReport: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ImportReportPage(
        result: args?['result'] as ImportResult? ?? ImportResult(success: false),
        schoolId: args?['schoolId'] ?? '',
        schoolCode: args?['schoolCode'] ?? '',
        type: args?['type'] ?? '',
      );
    },
  };

  static AttendanceBloc _createAttendanceBloc(BuildContext context) {
    final supabase = Supabase.instance.client;
    return AttendanceBloc(
      attendanceRepository: AttendanceRepository(supabase),
      classRepository: ClassRepository(supabase),
      studentRepository: StudentRepository(supabase),
      courseRepository: CourseRepository(supabase),
      teacherService: TeacherService(supabase: supabase),
    );
  }

  static void logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, schoolLogin, (route) => false);
  }
}