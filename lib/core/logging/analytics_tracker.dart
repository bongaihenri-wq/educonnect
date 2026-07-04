// lib/core/logging/analytics_tracker.dart
import 'app_logger.dart';

class AnalyticsTracker {
  static final AnalyticsTracker _instance = AnalyticsTracker._internal();
  factory AnalyticsTracker() => _instance;
  AnalyticsTracker._internal();

  final AppLogger _logger = AppLogger();

  // ─── Événements d'authentification ────────────────────────

  void trackLoginSuccess(String phone, String role) {
    _logger.logAnalytics(
      eventName: 'login_success',
      parameters: {
        'phone': _anonymizePhone(phone),
        'role': role,
      },
    );
  }

  void trackLoginFailed(String phone, String reason) {
    _logger.logAnalytics(
      eventName: 'login_failed',
      parameters: {
        'phone': _anonymizePhone(phone),
        'reason': reason,
      },
    );
  }

  void trackLogout(String userId) {
    _logger.logAnalytics(
      eventName: 'logout',
      parameters: {'user_id': userId},
    );
  }

  // ─── Événements de navigation ─────────────────────────────

  void trackScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    _logger.logAnalytics(
      eventName: 'screen_viewed',
      screenName: screenName,
      parameters: {
        'screen': screenName,
        ...?parameters,
      },
    );
  }

  // ─── Événements métier ────────────────────────────────────

  void trackAttendanceTaken(String className, int studentCount) {
    _logger.logAnalytics(
      eventName: 'attendance_taken',
      parameters: {
        'class': className,
        'student_count': studentCount,
      },
    );
  }

  void trackGradeViewed(String subject, String studentName) {
    _logger.logAnalytics(
      eventName: 'grade_viewed',
      parameters: {
        'subject': subject,
        'student': _anonymizeName(studentName),
      },
    );
  }

  void trackHomeworkCreated(String className) {
    _logger.logAnalytics(
      eventName: 'homework_created',
      parameters: {'class': className},
    );
  }

  void trackPaymentSubmitted(double amount, String currency) {
    _logger.logAnalytics(
      eventName: 'payment_submitted',
      parameters: {
        'amount': amount,
        'currency': currency,
      },
    );
  }

  void trackCommentSent(String recipientType) {
    _logger.logAnalytics(
      eventName: 'comment_sent',
      parameters: {'recipient_type': recipientType},
    );
  }

  // ─── Événements de performance ────────────────────────────

  void trackApiLatency(String endpoint, int durationMs) {
    _logger.logPerformance(
      operation: 'api_$endpoint',
      durationMs: durationMs,
    );
  }

  void trackScreenLoadTime(String screenName, int durationMs) {
    _logger.logPerformance(
      operation: 'screen_load_$screenName',
      durationMs: durationMs,
      screenName: screenName,
    );
  }

  // ─── Événements d'erreur UX ───────────────────────────────

  void trackEmptyState(String screenName, String dataType) {
    _logger.logAnalytics(
      eventName: 'empty_state_shown',
      screenName: screenName,
      parameters: {
        'screen': screenName,
        'data_type': dataType,
      },
    );
  }

  void trackErrorShown(String screenName, String errorType) {
    _logger.logAnalytics(
      eventName: 'error_shown',
      screenName: screenName,
      parameters: {
        'screen': screenName,
        'error_type': errorType,
      },
    );
  }

  // ─── Helpers ───────────────────────────────────────────────

  String _anonymizePhone(String phone) {
    if (phone.length < 4) return '***';
    return '${phone.substring(0, 2)}****${phone.substring(phone.length - 2)}';
  }

  String _anonymizeName(String name) {
    if (name.isEmpty) return '***';
    final parts = name.split(' ');
    return parts.map((p) => '${p[0]}***').join(' ');
  }
}