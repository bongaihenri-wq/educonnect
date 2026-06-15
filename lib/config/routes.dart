// lib/config/routes.dart
import 'package:educonnect/presentation/pages/admin/bulk_import_page.dart';
import 'package:educonnect/presentation/pages/parent/subscription_renewal_page.dart';
import 'package:educonnect/presentation/pages/super_admin/role_management/role_management_page.dart';
import 'package:educonnect/presentation/pages/super_admin/subscriptions/subscription_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pages
import '../presentation/pages/school_login_page.dart';
import '../presentation/pages/admin/admin_dashboard.dart';
import '../presentation/pages/admin/schedule_page.dart';
import '../presentation/pages/admin/homework_page.dart';
import '../presentation/pages/admin/grades_page.dart';
import '../presentation/pages/admin/messages_page.dart';
import '../presentation/pages/admin/teacher_tracking_page.dart';
import '../presentation/pages/admin/settings_page.dart';
import '../presentation/pages/admin/teachers_list_page.dart';
import '../presentation/pages/admin/parents_list_page.dart';
import '../presentation/pages/admin/class_list_page.dart';
import '../presentation/pages/admin/student_list_page.dart';
import '../presentation/pages/admin/classes_students_page.dart';
import '../presentation/pages/parent/parent_dashboard.dart';
import '../presentation/pages/teacher/teacher_dashboard.dart';
import '../presentation/pages/teacher/attendance/attendance_classes_page.dart';
import '../presentation/pages/teacher/comments_entry_page.dart';
import '../presentation/pages/teacher/comments_classes_page.dart';
import '../presentation/pages/teacher/grades_entry_page.dart';
import '../presentation/pages/teacher/grades_classes_page.dart';
import '../presentation/pages/teacher/teacher_schedule_full_page.dart';
import '../presentation/pages/teacher/teacher_reports_page.dart';
import '../presentation/pages/admin/admin_send_message_page.dart';


// ✅ AJOUTÉ : Pages de souscription + AuthStateRouter
import '../presentation/pages/auth_state_router.dart';
import '../presentation/pages/parent/payment_pending_page.dart';
import '../presentation/pages/parent/subscription_expired_page.dart';

// Super Admin pages
import '../presentation/pages/super_admin/super_admin_dashboard.dart';
import '../presentation/pages/super_admin/school_management/school_management_page.dart';
import '../presentation/pages/super_admin/school_management/school_detail_page.dart';
import '../presentation/pages/super_admin/role_management/role_management_page.dart';
import '../presentation/pages/super_admin/import_report_page.dart';
import '../presentation/pages/super_admin/import_preview_page.dart';
import '../presentation/pages/super_admin/subscriptions/subscription_dashboard_page.dart';
import '../presentation/pages/super_admin/support_dashboard_page.dart';
import '../presentation/pages/super_admin/parent_support_detail_page.dart';
  
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
  static const String subscriptionRenewal = '/parent/subscription-renewal';
  
  // ✅ AJOUTÉ : Routes de souscription
  static const String authRouter = '/auth';
  static const String paymentPending = '/parent/payment-pending';
  static const String subscriptionExpired = '/parent/subscription-expired';
  
  // Admin routes
  static const String adminTeachers = '/admin/teachers';
  static const String adminParents = '/admin/parents';
  static const String adminClassesStudents = '/admin/classes-students';
  static const String adminGradesPending = '/admin/grades-pending';
  static const String adminReports = '/admin/reports';
  static const String adminMessages = '/admin/messages';
  static const String adminTeacherTracking = '/admin/teacher-tracking';
  static const String adminSettings = '/admin/settings';
  
  // Routes pilotage
  static const String schedule = '/schedule';
  static const String homework = '/homework';
  static const String grades = '/grades';
  
  // Super Admin routes
  static const String superAdminDashboard = '/super-admin/dashboard';
  static const String schoolManagement = '/super-admin/schools';
  static const String schoolDetail = '/super-admin/school-detail';
  static const String subscriptionTracking = '/super-admin/subscriptions';
  static const String superAdminImport = '/super-admin/import';
  static const String subscriptionDashboard = '/super-admin/subscription-dashboard';
  static const String roleManagement = '/super-admin/roles';
  static const String supportDashboard = '/super-admin/support-dashboard';
  static const String parentSupportDetail = '/super-admin/parent-support-detail';
  
  static const String teacherAttendanceClasses = '/teacher/attendance/classes';
  static const String teacherAttendance = '/teacher/attendance';
  static const String classesStudents = '/classes_students';
  static const String teacherGradesClasses = '/teacher/grades-classes';
  static const String teacherGradesEntry = '/teacher/grades-entry';
  static const String teacherCommentsClasses = '/teacher/comments-classes';
  static const String teacherCommentsEntry = '/teacher/comments-entry';
  static const String teacherScheduleFull = '/teacher/schedule-full';
  static const String teacherReports = '/teacher/reports';

  static Map<String, WidgetBuilder> get routes => {
    // ✅ AJOUTÉ : AuthStateRouter comme route d'entrée alternative
    authRouter: (context) => const AuthStateRouter(),
    
    schoolLogin: (context) => const SchoolLoginPage(),
    teacherDashboard: (context) => const TeacherDashboard(),
    parentDashboard: (context) => const ParentDashboard(),
    adminDashboard: (context) => const AdminDashboard(),
    
    // ✅ AJOUTÉ : SubscriptionRenewal (déclaré en constante mais manquait dans le Map)
    subscriptionRenewal: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SubscriptionRenewalPage(
        parentId: args?['parentId'] ?? '',
        schoolId: args?['schoolId'],
        amount: args?['amount'] ?? 1000,
        currency: args?['currency'] ?? 'XOF',
        paymentPhoneNumber: args?['paymentPhoneNumber'],
        currentStatus: args?['currentStatus'],
        currentEndDate: args?['currentEndDate'] is String 
            ? DateTime.parse(args!['currentEndDate']) 
            : args?['currentEndDate'] as DateTime?,
        daysRemaining: args?['daysRemaining'],
      );
    },
    
    // ✅ AJOUTÉ : Routes de souscription
    paymentPending: (context) => const PaymentPendingPage(),
    subscriptionExpired: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SubscriptionExpiredPage(
        parentId: args?['parentId'] ?? '',
        schoolId: args?['schoolId'],
        expiresAt: args?['expiresAt'] is String 
            ? DateTime.parse(args!['expiresAt']) 
            : args?['expiresAt'] as DateTime?,
        daysRemaining: args?['daysRemaining'],
        amount: args?['amount'] ?? 1000,
        currency: args?['currency'] ?? 'XOF',
        paymentPhoneNumber: args?['paymentPhoneNumber'],
      );
    },
    
    // Admin routes
    adminTeachers: (context) => const TeachersListPage(),
    adminParents: (context) => const ParentsListPage(),
    adminClassesStudents: (context) => const ClassesStudentsPage(),
    adminMessages: (context) => const MessagesPage(),
    adminTeacherTracking: (context) => const TeacherTrackingPage(),
    adminSettings: (context) => const SettingsPage(),
    '/admin/send-message': (context) => const AdminSendMessagePage(),
    
    // Routes pilotage
    schedule: (context) => const SchedulePage(),
    homework: (context) => const HomeworkPage(),
    grades: (context) => const GradesPage(),
    
    // Super Admin routes
    superAdminDashboard: (context) => const SuperAdminDashboardPage(),
    schoolManagement: (context) => const SchoolManagementPage(),
    schoolDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SchoolDetailPage(school: args?['school'] ?? {});
    },
    supportDashboard: (context) => const SupportDashboardPage(),
    parentSupportDetail: (context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return ParentSupportDetailPage(parentId: args?['parentId'] ?? '');
},
    superAdminImport: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return BulkImportPage(
        schoolId: args?['schoolId'] ?? '',
        schoolCode: args?['schoolCode'] ?? '',
        schoolYear: args?['schoolYear'] ?? '2024-2025',
      );
    },

    roleManagement: (context) => const RoleManagementPage(),
    subscriptionDashboard: (context) => const SubscriptionDashboardPage(),
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