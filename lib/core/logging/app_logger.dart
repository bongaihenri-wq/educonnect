// lib/core/logging/app_logger.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

enum LogLevel { debug, info, warning, error, fatal }

enum LogCategory {
  auth,
  api,
  bloc,
  ui,
  performance,
  error,
  analytics,
  business,
}

class AppLog {
  final String id;
  final DateTime createdAt;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final String? userId;
  final String? userRole;
  final String? schoolId;
  final String? phone;
  final String? screenName;
  final String? blocName;
  final String? apiEndpoint;
  final String? apiMethod;
  final int? apiStatusCode;
  final int? durationMs;
  final Map<String, dynamic>? metadata;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final String? stacktrace;
  final String? errorCode;
  final String? sessionId;

  AppLog({
    required this.id,
    required this.createdAt,
    required this.level,
    required this.category,
    required this.message,
    this.userId,
    this.userRole,
    this.schoolId,
    this.phone,
    this.screenName,
    this.blocName,
    this.apiEndpoint,
    this.apiMethod,
    this.apiStatusCode,
    this.durationMs,
    this.metadata,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
    this.stacktrace,
    this.errorCode,
    this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'level': level.name,
      'category': category.name,
      'message': message,
      'user_id': userId,
      'user_role': userRole,
      'school_id': schoolId,
      'phone': phone,
      'screen_name': screenName,
      'bloc_name': blocName,
      'api_endpoint': apiEndpoint,
      'api_method': apiMethod,
      'api_status_code': apiStatusCode,
      'duration_ms': durationMs,
      'metadata': metadata,
      'device_model': deviceModel,
      'os_version': osVersion,
      'app_version': appVersion,
      'stacktrace': stacktrace,
      'error_code': errorCode,
      'session_id': sessionId,
    };
  }
}

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  SupabaseClient? _supabase;
  String? _sessionId;
  String? _userId;
  String? _userRole;
  String? _schoolId;
  String? _phone;
  String? _deviceModel;
  String? _osVersion;
  String? _appVersion;

  final List<AppLog> _localBuffer = [];
  bool _initialized = false;

  Future<void> initialize(SupabaseClient supabase) async {
    if (_initialized) return;

    _supabase = supabase;
    _sessionId = const Uuid().v4();

    await _loadDeviceInfo();
    await _loadUserInfo();

    _initialized = true;

    logInfo(
      category: LogCategory.auth,
      message: 'Logger initialized',
      metadata: {'session_id': _sessionId},
    );
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        _osVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceModel = iosInfo.utsname.machine;
        _osVersion = 'iOS ${iosInfo.systemVersion}';
      }

      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      _deviceModel = 'unknown';
      _osVersion = 'unknown';
      _appVersion = 'unknown';
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');
      _userRole = prefs.getString('role');
      _schoolId = prefs.getString('school_id');
      _phone = prefs.getString('phone');
    } catch (e) {
      // Silencieux
    }
  }

  void setUserContext({
    String? userId,
    String? userRole,
    String? schoolId,
    String? phone,
  }) {
    _userId = userId;
    _userRole = userRole;
    _schoolId = schoolId;
    _phone = phone;
  }

  void clearUserContext() {
    _userId = null;
    _userRole = null;
    _schoolId = null;
    _phone = null;
  }

  // --- Methodes publiques de log ---

  void logDebug({
    required LogCategory category,
    required String message,
    String? screenName,
    String? blocName,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      level: LogLevel.debug,
      category: category,
      message: message,
      screenName: screenName,
      blocName: blocName,
      metadata: metadata,
    );
  }

  void logInfo({
    required LogCategory category,
    required String message,
    String? screenName,
    String? blocName,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      level: LogLevel.info,
      category: category,
      message: message,
      screenName: screenName,
      blocName: blocName,
      metadata: metadata,
    );
  }

  void logWarning({
    required LogCategory category,
    required String message,
    String? screenName,
    String? blocName,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      level: LogLevel.warning,
      category: category,
      message: message,
      screenName: screenName,
      blocName: blocName,
      errorCode: errorCode,
      metadata: metadata,
    );
  }

  void logError({
    required LogCategory category,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    String? screenName,
    String? blocName,
    String? apiEndpoint,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      level: LogLevel.error,
      category: category,
      message: message,
      screenName: screenName,
      blocName: blocName,
      apiEndpoint: apiEndpoint,
      error: error,
      stackTrace: stackTrace,
      errorCode: errorCode,
      metadata: metadata,
    );
  }

  void logFatal({
    required LogCategory category,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    String? screenName,
    String? blocName,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      level: LogLevel.fatal,
      category: category,
      message: message,
      screenName: screenName,
      blocName: blocName,
      error: error,
      stackTrace: stackTrace,
      errorCode: errorCode,
      metadata: metadata,
    );
  }

  void logApi({
    required String endpoint,
    required String method,
    required int statusCode,
    required int durationMs,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      level: statusCode >= 400 ? LogLevel.error : LogLevel.info,
      category: LogCategory.api,
      message: errorMessage ?? 'API $method $endpoint -> $statusCode',
      apiEndpoint: endpoint,
      apiMethod: method,
      apiStatusCode: statusCode,
      durationMs: durationMs,
      metadata: metadata,
    );
  }

  void logPerformance({
    required String operation,
    required int durationMs,
    String? screenName,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      level: durationMs > 3000 ? LogLevel.warning : LogLevel.info,
      category: LogCategory.performance,
      message: 'Performance: $operation took ${durationMs}ms',
      screenName: screenName,
      durationMs: durationMs,
      metadata: metadata,
    );
  }

  void logAnalytics({
    required String eventName,
    String? screenName,
    Map<String, dynamic>? parameters,
  }) {
    _log(
      level: LogLevel.info,
      category: LogCategory.analytics,
      message: 'Analytics: $eventName',
      screenName: screenName,
      metadata: parameters,
    );
  }

  // --- Log interne ---

  void _log({
    required LogLevel level,
    required LogCategory category,
    required String message,
    String? screenName,
    String? blocName,
    String? apiEndpoint,
    String? apiMethod,
    int? apiStatusCode,
    int? durationMs,
    Object? error,
    StackTrace? stackTrace,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) {
    final log = AppLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      level: level,
      category: category,
      message: message,
      userId: _userId,
      userRole: _userRole,
      schoolId: _schoolId,
      phone: _phone,
      screenName: screenName,
      blocName: blocName,
      apiEndpoint: apiEndpoint,
      apiMethod: apiMethod,
      apiStatusCode: apiStatusCode,
      durationMs: durationMs,
      metadata: metadata,
      deviceModel: _deviceModel,
      osVersion: _osVersion,
      appVersion: _appVersion,
      stacktrace: stackTrace?.toString(),
      errorCode:
          errorCode ?? (error != null ? error.runtimeType.toString() : null),
      sessionId: _sessionId,
    );

    // 1. Log dans la console (toujours)
    _printToConsole(log);

    // 2. FLUSH IMMEDIAT (pas de buffer pendant les tests)
    _flushLogImmediately(log);
  }

  void _printToConsole(AppLog log) {
    final prefix = {
      LogLevel.debug: 'DEBUG',
      LogLevel.info: 'INFO',
      LogLevel.warning: 'WARN',
      LogLevel.error: 'ERROR',
      LogLevel.fatal: 'FATAL',
    }[log.level];

    final StringBuffer sb = StringBuffer();
    sb.writeln('');
    sb.writeln(
        '[$prefix] [${log.level.name.toUpperCase()}] ${log.category.name.toUpperCase()}');
    sb.writeln(
        '   Device: ${log.deviceModel ?? 'unknown'} | ${log.osVersion ?? 'unknown'} | v${log.appVersion ?? 'unknown'}');
    sb.writeln(
        '   User: ${log.userRole ?? 'anon'} | ${log.phone ?? 'no phone'} | ${log.schoolId ?? 'no school'}');
    sb.writeln(
        '   Screen: ${log.screenName ?? 'no screen'} | Bloc: ${log.blocName ?? 'no bloc'}');
    sb.writeln('   Message: ${log.message}');
    if (log.errorCode != null) {
      sb.writeln('   Error: ${log.errorCode}');
    }
    if (log.stacktrace != null) {
      sb.writeln('   Stack:');
      sb.writeln('${log.stacktrace}');
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print(sb.toString());
    }
  }

  Future<void> _flushLogImmediately(AppLog log) async {
    if (_supabase == null) {
      print('[FLUSH] Supabase null, log perdu: ${log.message}');
      return;
    }

    try {
      await _supabase!.from('app_logs').insert(log.toMap());
      print('[FLUSH] Log envoye: ${log.message}');
    } catch (e) {
      print('[FLUSH] Erreur pour "${log.message}": $e');
    }
  }

  Future<void> _flushBuffer() async {
    if (_localBuffer.isEmpty || _supabase == null) {
      print(
          '[FLUSH] Buffer=${_localBuffer.length}, Supabase=${_supabase != null}');
      return;
    }

    final logsToSend = List<AppLog>.from(_localBuffer);
    _localBuffer.clear();

    print('[FLUSH] Envoi ${logsToSend.length} logs...');

    try {
      final data = logsToSend.map((l) => l.toMap()).toList();
      print('[FLUSH] Premiere entree: ${data.first}');

      await _supabase!.from('app_logs').insert(data);
      print('[FLUSH] SUCCES ! ${logsToSend.length} logs envoyes');
    } catch (e, stackTrace) {
      print('[FLUSH] ERREUR: $e');
      print('[FLUSH] STACK: $stackTrace');
      _localBuffer.addAll(logsToSend);
    }
  }

  // Flush manuel (ex: avant logout)
  Future<void> flush() async {
    await _flushBuffer();
  }
}
