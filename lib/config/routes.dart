import 'package:flutter/material.dart';
import '../presentation/pages/admin/admin_dashboard.dart';
import '../presentation/pages/admin/bulk_import_page.dart';
import '../presentation/pages/parent/parent_dashboard.dart';
import '../presentation/pages/school_login_page.dart';
import '../presentation/pages/teacher/teacher_dashboard.dart';
import '/presentation/pages/teacher/attendance/attendance_classes_page.dart'; // NOUVEAU
import '../presentation/pages/teacher/attendance_page.dart';

class AppRoutes {
  static const String schoolLogin = '/';
  static const String teacherDashboard = '/teacher/dashboard';
  static const String parentDashboard = '/parent/dashboard';
  static const String adminDashboard = '/admin/dashboard';
  static const String childDetail = '/parent/child/detail';
  static const String attendance = '/attendance';
  
  // Routes enseignant - APPEL
  static const String teacherAttendanceClasses = '/teacher/attendance/classes'; // Étape 1: Choisir classe
  static const String teacherAttendance = '/teacher/attendance';               // Étape 2: Faire l'appel
  
  static const String adminBulkImport = '/admin/import';

  static Map<String, WidgetBuilder> get routes => {
    schoolLogin: (context) => const SchoolLoginPage(),
    teacherDashboard: (context) => const TeacherDashboard(),
    parentDashboard: (context) => const ParentDashboard(),
    adminDashboard: (context) => const AdminDashboard(),
    attendance: (context) => const AttendancePage(classId: '', className: '',),
    
    // ÉTAPE 1: Page de sélection des classes (pas d'arguments requis)
    teacherAttendanceClasses: (context) => const AttendanceClassesPage(),
    
    // ÉTAPE 2: Page d'appel (classId requis)
    teacherAttendance: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null || args['classId'] == null) {
        return const Scaffold(
          body: Center(
            child: Text('Erreur: Aucune classe sélectionnée'),
          ),
        );
      }
      return AttendancePage(
        classId: args['classId'] as String,
        className: args['className'] as String? ?? 'Classe',
        subjectId: args['subjectId'] as String?,
        subjectName: args['subjectName'] as String?,
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
  };
  
  /// Navigation helpers
  
  // ÉTAPE 1: Voir les classes de l'enseignant
  static void navigateToAttendanceClasses(BuildContext context) {
    Navigator.pushNamed(context, teacherAttendanceClasses);
  }
  
  // ÉTAPE 2: Faire l'appel dans une classe spécifique
  static void navigateToAttendance(
    BuildContext context, {
    required String classId,
    required String className,
    String? subjectId,
    String? subjectName,
  }) {
    Navigator.pushNamed(
      context,
      teacherAttendance,
      arguments: {
        'classId': classId,
        'className': className,
        'subjectId': subjectId,
        'subjectName': subjectName,
      },
    );
  }
  
  static void navigateToTeacherDashboard(BuildContext context) {
    Navigator.pushNamed(context, teacherDashboard);
  }
  
  static void navigateToParentDashboard(BuildContext context) {
    Navigator.pushNamed(context, parentDashboard);
  }
  
  static void navigateToAdminDashboard(BuildContext context) {
    Navigator.pushNamed(context, adminDashboard);
  }
  static void navigateToAttendancePage(BuildContext context) {
    Navigator.pushNamed(context, attendance);
  }

  static void navigateToBulkImport(
    BuildContext context, {
    String? schoolId,
    String? schoolCode,
    String? schoolYear,
  }) {
    Navigator.pushNamed(
      context,
      adminBulkImport,
      arguments: {
        'schoolId': schoolId,
        'schoolCode': schoolCode,
        'schoolYear': schoolYear,
      },
    );
  }
  
  static void logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      schoolLogin,
      (route) => false,
    );
  }
}
