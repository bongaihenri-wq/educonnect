// lib/core/analytics/analytics_event.dart

/// Modèle d'événement analytics pour EduConnect.
///
/// Chaque événement contient :
/// - name : Nom de l'événement (snake_case)
/// - timestamp : Date/heure de l'événement
/// - userId : ID utilisateur (anonymisé si besoin)
/// - role : Rôle de l'utilisateur (parent, teacher, admin, etc.)
/// - schoolId : ID de l'école (pour isolation)
/// - parameters : Données contextuelles (écran, feature, etc.)
/// - sessionId : ID de session (pour regrouper les événements)
import 'dart:math';

class AnalyticsEvent {
  final String name;
  final DateTime timestamp;
  final String? userId;
  final String? role;
  final String? schoolId;
  final Map<String, dynamic> parameters;
  final String sessionId;

  AnalyticsEvent({
    required this.name,
    this.userId,
    this.role,
    this.schoolId,
    this.parameters = const {},
    String? sessionId,
  })  : timestamp = DateTime.now(),
        sessionId = sessionId ?? _generateSessionId();

  /// Convertit en Map pour envoi Supabase/JSON
  Map<String, dynamic> toJson() => {
        'event_name': name,
        'timestamp': timestamp.toIso8601String(),
        'user_id': userId,
        'role': role,
        'school_id': schoolId,
        'parameters': parameters,
        'session_id': sessionId,
        'device_info': {
          'platform': 'mobile', // Flutter
          'app_version': parameters['app_version'],
        },
      };

  static String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
  }

  @override
  String toString() => 'AnalyticsEvent[$name] @ ${timestamp.toIso8601String()}';
}

/// Événements prédéfinis (taxonomie)
class AnalyticsEvents {
  // App lifecycle
  static const String appLaunched = 'app_launched';
  static const String appResumed = 'app_resumed';
  static const String appPaused = 'app_paused';
  static const String appTerminated = 'app_terminated';

  // Auth
  static const String loginScreenViewed = 'login_screen_viewed';
  static const String loginAttempted = 'login_attempted';
  static const String loginSuccess = 'login_success';
  static const String loginFailed = 'login_failed';
  static const String logout = 'logout';

  // Navigation / Screens
  static const String screenViewed = 'screen_viewed';

  // Parent features
  static const String parentDashboardLoaded = 'parent_dashboard_loaded';
  static const String childDetailOpened = 'child_detail_opened';
  static const String notesViewed = 'notes_viewed';
  static const String attendanceViewed = 'attendance_viewed';
  static const String homeworksViewed = 'homeworks_viewed';
  static const String messagesViewed = 'messages_viewed';
  static const String timetableViewed = 'timetable_viewed';

  // Teacher features
  static const String teacherDashboardLoaded = 'teacher_dashboard_loaded';
  static const String attendanceTaken = 'attendance_taken';
  static const String gradeEntered = 'grade_entered';
  static const String homeworkAssigned = 'homework_assigned';
  static const String messageSent = 'message_sent';

  // Admin features
  static const String adminDashboardLoaded = 'admin_dashboard_loaded';
  static const String studentCreated = 'student_created';
  static const String teacherCreated = 'teacher_created';

  // Errors & UX
  static const String errorOccurred = 'error_occurred';
  static const String emptyStateShown = 'empty_state_shown';
  static const String frustrationDetected = 'frustration_detected';
  static const String retryAttempted = 'retry_attempted';
  static const String retrySuccess = 'retry_success';

  // Subscription
  static const String subscriptionChecked = 'subscription_checked';
  static const String subscriptionExpired = 'subscription_expired';
  static const String paymentInitiated = 'payment_initiated';
  static const String paymentSuccess = 'payment_success';
  static const String paymentFailed = 'payment_failed';
}
