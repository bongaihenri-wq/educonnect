// lib/core/logging/global_error_handler.dart
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_logger.dart';

class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  final AppLogger _logger = AppLogger();

  void initialize() {
    // 1. Capture les erreurs Flutter (build, layout, etc.)
    FlutterError.onError = (FlutterErrorDetails details) {
      _logger.logFatal(
        category: LogCategory.error,
        message: 'FlutterError: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
        screenName: _getCurrentScreen(),
      );

      // Appeler le handler par défaut pour le debug
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // 2. Capture les erreurs async non catchées
    PlatformDispatcher.instance.onError = (error, stack) {
      _logger.logFatal(
        category: LogCategory.error,
        message: 'PlatformDispatcher error: $error',
        error: error,
        stackTrace: stack,
        screenName: _getCurrentScreen(),
      );
      return true; // Empêche le crash de l'app
    };

    // 3. Capture les erreurs dans les Zones (isolates)
    Isolate.current.addErrorListener(RawReceivePort((pair) {
      final error = pair[0];
      final stack = pair[1];
      _logger.logFatal(
        category: LogCategory.error,
        message: 'Isolate error: $error',
        error: error,
        stackTrace: stack,
      );
    }).sendPort);

    _logger.logInfo(
      category: LogCategory.auth,
      message: 'GlobalErrorHandler initialized',
    );
  }

  String? _getCurrentScreen() {
    // Simplifié - peut être amélioré avec NavigatorObserver
    return null;
  }

  // Wrapper pour exécuter du code avec capture d'erreur
  Future<T> runWithErrorHandling<T>(
    Future<T> Function() action, {
    String? operationName,
    String? screenName,
  }) async {
    try {
      return await action();
    } catch (e, stackTrace) {
      _logger.logError(
        category: LogCategory.error,
        message: 'Error in ${operationName ?? 'unknown operation'}: $e',
        error: e,
        stackTrace: stackTrace,
        screenName: screenName,
      );
      rethrow;
    }
  }
}
