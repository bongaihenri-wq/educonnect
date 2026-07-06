// lib/core/analytics/analytics_tracker.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'analytics_event.dart';

class AnalyticsTracker {
  static final AnalyticsTracker _instance = AnalyticsTracker._internal();
  factory AnalyticsTracker() => _instance;
  AnalyticsTracker._internal();

  static const int _bufferSize = 20;
  static const Duration _flushInterval = Duration(seconds: 30);
  static const String _tableName = 'analytics_events';

  final List<AnalyticsEvent> _buffer = [];
  Timer? _flushTimer;
  String? _currentUserId;
  String? _currentRole;
  String? _currentSchoolId;
  String? _currentSessionId;
  bool _isInitialized = false;

  void initialize({
    String? userId,
    String? role,
    String? schoolId,
  }) {
    _currentUserId = userId;
    _currentRole = role;
    _currentSchoolId = schoolId;
    _currentSessionId =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    _isInitialized = true;

    _startFlushTimer();

    track(AnalyticsEvents.appLaunched, parameters: {
      'init_user_id': userId,
      'init_role': role,
    });

    debugPrint('📊 AnalyticsTracker initialisé (session: $_currentSessionId)');
  }

  void updateUser({
    String? userId,
    String? role,
    String? schoolId,
  }) {
    _currentUserId = userId ?? _currentUserId;
    _currentRole = role ?? _currentRole;
    _currentSchoolId = schoolId ?? _currentSchoolId;
  }

  void track(String eventName, {Map<String, dynamic> parameters = const {}}) {
    if (!_isInitialized) {
      debugPrint(
          '⚠️ AnalyticsTracker non initialisé, event ignoré: $eventName');
      return;
    }

    final event = AnalyticsEvent(
      name: eventName,
      userId: _currentUserId,
      role: _currentRole,
      schoolId: _currentSchoolId,
      sessionId: _currentSessionId,
      parameters: parameters,
    );

    _buffer.add(event);

    // ✅ Log détaillé
    debugPrint('📊 ==========================================');
    debugPrint('📊 EVENT: $eventName');
    debugPrint('📊 User: $_currentUserId | Role: $_currentRole');
    debugPrint('📊 Params: $parameters');
    debugPrint('📊 Buffer size: ${_buffer.length}/$_bufferSize');
    debugPrint('📊 ==========================================');

    if (_buffer.length >= _bufferSize) {
      debugPrint('📊 Buffer plein ($_bufferSize), flush immédiat');
      _flush();
    }
  }

  void trackScreen(String screenName,
      {Map<String, dynamic> parameters = const {}}) {
    track(AnalyticsEvents.screenViewed, parameters: {
      'screen_name': screenName,
      ...parameters,
    });
  }

  void trackError(String errorType, String message,
      {Map<String, dynamic> parameters = const {}}) {
    track(AnalyticsEvents.errorOccurred, parameters: {
      'error_type': errorType,
      'error_message': message,
      ...parameters,
    });
  }

  void trackEmptyState(String screenName, String emptyType) {
    track(AnalyticsEvents.emptyStateShown, parameters: {
      'screen_name': screenName,
      'empty_type': emptyType,
    });
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) {
      debugPrint('📊 Timer flush (30s)');
      _flush();
    });
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) {
      debugPrint('📊 Buffer vide, rien à flush');
      return;
    }

    final eventsToSend = List<AnalyticsEvent>.from(_buffer);
    _buffer.clear();

    try {
      final supabase = Supabase.instance.client;
      final rows = eventsToSend.map((e) => e.toJson()).toList();

      debugPrint('📊 FLUSH: ${rows.length} events vers Supabase...');
      for (final row in rows) {
        debugPrint('📊   → ${row['event_name']} | ${row['timestamp']}');
      }

      await supabase.from(_tableName).insert(rows);

      debugPrint('✅ ${eventsToSend.length} events envoyés avec succès');
    } catch (e) {
      debugPrint('❌ Erreur flush analytics: $e');
      debugPrint('❌ Events remis dans le buffer: ${eventsToSend.length}');
      _buffer.insertAll(0, eventsToSend);
    }
  }

  Future<void> flushImmediately() async {
    debugPrint('📊 Flush immédiat demandé');
    await _flush();
  }

  void dispose() {
    _flushTimer?.cancel();
    flushImmediately();
    _isInitialized = false;
    debugPrint('📊 AnalyticsTracker disposed');
  }
}

// Instance globale
final analytics = AnalyticsTracker();
