// lib/config/routes.dart
import 'package:educonnect/presentation/blocs/attendance/attendance_page.dart' show AttendancePage;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==================== AUTH & ROUTAGE ====================
import '../presentation/pages/school_login_page.dart';
import '../presentation/pages/auth_state_router.dart';

// ==================== PARENT ====================
import '../presentation/pages/parent/parent_dashboard.dart';
import '../presentation/pages/parent/payment_pending_page.dart';
import '../presentation/pages/parent/subscription_expired_page.dart';
import '../presentation/pages/parent/subscription_renewal_page.dart';

// ==================== TEACHER ====================
import '../presentation/pages/teacher/teacher_dashboard.dart';
import '../presentation/pages/teacher/attendance/attendance_classes_page.dart';
import '../presentation/pages/teacher/comments_entry_page.dart';
import '../presentation/pages/teacher/comments_classes_page.dart';
import '../presentation/pages/teacher/grades_entry_page.dart';
import '../presentation/pages/teacher/grades_classes_page.dart';
import '../presentation/pages/teacher/teacher_schedule_full_page.dart';
import '../presentation/pages/teacher/teacher_reports_page.dart';

// ==================== ADMIN ÉCOLE ====================
import '../presentation/pages/admin/admin_dashboard.dart';
import '../presentation/pages/admin/schedule_page.dart';
import '../presentation/pages/admin/homework_page.dart';
import '../presentation/pages/admin/grades_page.dart';
import '../presentation/pages/admin/messages_page.dart';
import '../presentation/pages/admin/teacher_tracking_page.dart';
import '../presentation/pages/admin/settings_page.dart';
import '../presentation/pages/admin/teachers_list_page.dart';
import '../presentation/pages/admin/parents_list_page.dart';
import '../presentation/pages/admin/classes_students_page.dart';
import '../presentation/pages/admin/admin_send_message_page.dart';
import '../presentation/pages/admin/bulk_import_page.dart';

// ==================== ASSISTANT & PRINCIPAL ====================
import '../presentation/pages/assistant/assistant_dashboard.dart';
import '../presentation/pages/principal/principal_dashboard.dart';

// ==================== SUPER ADMIN ====================
import '../presentation/pages/super_admin/super_admin_dashboard.dart';
import '../presentation/pages/super_admin/school_management/school_management_page.dart';
import '../presentation/pages/super_admin/school_management/school_detail_page.dart';
import '../presentation/pages/super_admin/role_management/role_management_page.dart';
import '../presentation/pages/super_admin/role_management/role_users_list_page.dart';
import '../presentation/pages/super_admin/subscriptions/subscription_dashboard_page.dart';
import '../presentation/pages/super_admin/support_dashboard_page.dart';
import '../presentation/pages/super_admin/parent_support_detail_page.dart';
import '../presentation/pages/super_admin/school_year_management_page.dart';
import '../presentation/pages/super_admin/commercial_dashboard_page.dart';
import '../presentation/pages/super_admin/school_trimesters_page.dart';

// ==================== BLOCS & REPOSITORIES ====================
import '../presentation/blocs/attendance/attendance_bloc.dart';
import '../presentation/blocs/attendance/attendance_event.dart';
import '../presentation/blocs/auth_bloc/auth_bloc.dart' as auth;

import '../data/repositories/attendance_repository.dart';
import '../data/repositories/class_repository.dart';
import '../data/repositories/student_repository.dart';
import '../data/repositories/course_repository.dart';
import '../services/teacher_service.dart';

class AppRoutes {
  // -------------------- AUTH --------------------
  static const String schoolLogin = '/login';
  static const String authRouter = '/auth';
  
  // -------------------- PARENT --------------------
  static const String parentDashboard = '/parent/dashboard';
  static const String paymentPending = '/parent/payment-pending';
  static const String subscriptionExpired = '/parent/subscription-expired';
  static const String subscriptionRenewal = '/parent/subscription-renewal';
  
  // -------------------- TEACHER --------------------
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherAttendanceClasses = '/teacher/attendance/classes';
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherGradesClasses = '/teacher/grades-classes';
  static const String teacherGradesEntry = '/teacher/grades-entry';
  static const String teacherCommentsClasses = '/teacher/comments-classes';
  static const String teacherCommentsEntry = '/teacher/comments-entry';
  static const String teacherScheduleFull = '/teacher/schedule-full';
  static const String teacherReports = '/teacher/reports';
  
  // -------------------- ADMIN ÉCOLE --------------------
  static const String adminDashboard = '/admin/dashboard';
  static const String adminTeachers = '/admin/teachers';
  static const String adminParents = '/admin/parents';
  static const String adminClassesStudents = '/admin/classes-students';
  static const String adminGradesPending = '/admin/grades-pending';
  static const String adminReports = '/admin/reports';
  static const String adminMessages = '/admin/messages';
  static const String adminTeacherTracking = '/admin/teacher-tracking';
  static const String adminSettings = '/admin/settings';
  static const String adminSendMessage = '/admin/send-message';
  static const String adminBulkImport = '/admin/bulk-import';
  
  // Routes pilotage
  static const String schedule = '/schedule';
  static const String homework = '/homework';
  static const String grades = '/grades';
  
  // -------------------- ASSISTANT & PRINCIPAL --------------------
  static const String assistantDashboard = '/assistant/dashboard';
  static const String principalDashboard = '/principal/dashboard';
  
  // -------------------- SUPER ADMIN --------------------
  static const String superAdminDashboard = '/super-admin/dashboard';
  static const String schoolManagement = '/super-admin/schools';
  static const String schoolDetail = '/super-admin/school-detail';
  static const String subscriptionTracking = '/super-admin/subscriptions';
  static const String superAdminImport = '/super-admin/import';
  static const String subscriptionDashboard = '/super-admin/subscription-dashboard';
  static const String roleManagement = '/super-admin/roles';
  static const String supportDashboard = '/super-admin/support-dashboard';
  static const String parentSupportDetail = '/super-admin/parent-support-detail';
  static const String schoolYearManagement = '/super-admin/school-year-management';
  static const String commercialDashboard = '/super-admin/commercial-dashboard';
  static const String roleUsersList = '/super-admin/role-users-list';
  static const String schoolTrimesters = '/super-admin/school-trimesters';

  // -------------------- ANCIENNES ROUTES (compatibilité) --------------------
  static const String classesStudents = '/classes_students';

  static Map<String, WidgetBuilder> get routes => {
    // AUTH
    authRouter: (context) => const AuthStateRouter(),
    schoolLogin: (context) => const SchoolLoginPage(),
    
    // PARENT
    parentDashboard: (context) => const ParentDashboard(),
    paymentPending: (context) => const PaymentPendingPage(),
    subscriptionExpired: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final expiresAtRaw = args?['expiresAt'];
      return SubscriptionExpiredPage(
        parentId: args?['parentId'] ?? '',
        schoolId: args?['schoolId'],
        expiresAt: expiresAtRaw is String 
            ? DateTime.tryParse(expiresAtRaw) 
            : expiresAtRaw as DateTime?,
        daysRemaining: args?['daysRemaining'],
        amount: args?['amount'] ?? 1000,
        currency: args?['currency'] ?? 'XOF',
        paymentPhoneNumber: args?['paymentPhoneNumber'],
      );
    },
    subscriptionRenewal: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final endDateRaw = args?['currentEndDate'];
      return SubscriptionRenewalPage(
        parentId: args?['parentId'] ?? '',
        schoolId: args?['schoolId'],
        amount: args?['amount'] ?? 1000,
        currency: args?['currency'] ?? 'XOF',
        paymentPhoneNumber: args?['paymentPhoneNumber'],
        currentStatus: args?['currentStatus'],
        currentEndDate: endDateRaw is String 
            ? DateTime.tryParse(endDateRaw) 
            : endDateRaw as DateTime?,
        daysRemaining: args?['daysRemaining'],
      );
    },
    
    // TEACHER
    teacherDashboard: (context) => const TeacherDashboard(),
    teacherScheduleFull: (context) => const TeacherScheduleFullPage(),
    
    // ✅ CORRIGÉ : Récupération des arguments pour TeacherReportsPage
    teacherReports: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return TeacherReportsPage(
        teacherId: args?['teacherId'] ?? '',
        schoolId: args?['schoolId'] ?? '',
        subject: args?['subject'] ?? '',
      );
    },
    
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
    
    teacherGradesClasses: (context) => const GradesClassesPage(),
    teacherGradesEntry: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return GradesEntryPage(
        classId: args?['classId'] ?? '',
        className: args?['className'] ?? '',
      );
    },
    
    teacherCommentsClasses: (context) => const CommentsClassesPage(),
    teacherCommentsEntry: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return CommentsEntryPage(
        classId: args?['classId'] ?? '',
        className: args?['className'] ?? '',
      );
    },
    
    // ADMIN ÉCOLE
    adminDashboard: (context) => const AdminDashboard(),
    adminTeachers: (context) => const TeachersListPage(),
    adminParents: (context) => const ParentsListPage(),
    adminClassesStudents: (context) => const ClassesStudentsPage(),
    classesStudents: (context) => const ClassesStudentsPage(),
    adminGradesPending: (context) => const GradesPage(),
    adminReports: (context) => const AdminDashboard(),
    adminMessages: (context) => const MessagesPage(),
    adminTeacherTracking: (context) => const TeacherTrackingPage(),
    adminSettings: (context) => const SettingsPage(),
    adminSendMessage: (context) => const AdminSendMessagePage(),
    adminBulkImport: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return BulkImportPage(
        schoolId: args?['schoolId'] ?? '',
        schoolCode: args?['schoolCode'] ?? '',
        schoolYear: args?['schoolYear'] ?? '2024-2025',
      );
    },
    
    // Routes pilotage
    schedule: (context) => const SchedulePage(),
    homework: (context) => const HomeworkPage(),
    grades: (context) => const GradesPage(),
    
    // ✅ CORRIGÉ : Récupération des arguments pour AssistantDashboard
      assistantDashboard: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return AssistantDashboard(
        countryCode: args?['countryCode'] ?? '+225',
      );
    },
    
    // ✅ CORRIGÉ : Récupération des arguments pour PrincipalDashboard
   principalDashboard: (context) => const PrincipalDashboard(),
    
    // SUPER ADMIN
    superAdminDashboard: (context) => const SuperAdminDashboardPage(),
    schoolManagement: (context) => const SchoolManagementPage(),
    schoolDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SchoolDetailPage(school: args?['school'] ?? {});
    },
    // ✅ CORRIGÉ : Ajout de subscriptionTracking dans le Map
    subscriptionTracking: (context) => const SubscriptionDashboardPage(),
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
    schoolTrimesters: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SchoolTrimestersPage(
        schoolId: args?['schoolId'] as String? ?? '',
        schoolName: args?['schoolName'] as String? ?? 'École',
      );
    },
  
    roleManagement: (context) => const RoleManagementPage(),
    subscriptionDashboard: (context) => const SubscriptionDashboardPage(),
    schoolYearManagement: (context) => const SchoolYearManagementPage(),
    roleUsersList: (context) => const RoleUsersListPage(),
    commercialDashboard: (context) => const CommercialDashboardPage(),
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