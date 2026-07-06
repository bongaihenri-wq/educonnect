// lib/core/exceptions/app_exception.dart

/// Exception personnalisée pour EduConnect avec type et message utilisateur.
///
/// EFFET RÉEL : Transforme les erreurs techniques (PostgrestError 42501,
/// timeout, etc.) en messages compréhensibles pour l'utilisateur.
///
/// Types d'erreurs identifiés dans l'audit D5 :
/// - network : Timeout, 3G coupé, pas de connexion
/// - server : Erreur Supabase (500, 503)
/// - auth : JWT expiré, non authentifié (401)
/// - permission : RLS denial (403, 42501)
/// - notFound : Donnée non trouvée (404)
/// - validation : Donnée invalide (400, 23505 duplicate key)
/// - unknown : Erreur non classifiée
class AppException implements Exception {
  final String type;
  final String message;
  final String? userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.type,
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
  });

  /// Message affiché à l'utilisateur (jamais technique)
  String get displayMessage {
    return userMessage ?? _defaultUserMessage;
  }

  String get _defaultUserMessage {
    switch (type) {
      case 'network':
        return 'Connexion instable. Vérifiez votre connexion internet et réessayez.';
      case 'server':
        return 'Le serveur est temporairement indisponible. Veuillez réessayer dans quelques instants.';
      case 'auth':
        return 'Votre session a expiré. Veuillez vous reconnecter.';
      case 'permission':
        return 'Vous n\'avez pas accès à cette ressource. Contactez l\'administration.';
      case 'notFound':
        return 'Donnée non trouvée. Elle a peut-être été supprimée.';
      case 'validation':
        return 'Donnée invalide. Veuillez vérifier les informations saisies.';
      default:
        return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }

  /// Si l'erreur est récupérable (on peut réessayer)
  bool get isRetryable {
    return type == 'network' || type == 'server';
  }

  @override
  String toString() => 'AppException[$type]: $message';

  // ═══════════════════════════════════════════════════
  // FACTORY : Création depuis une erreur Supabase/Flutter
  // ═══════════════════════════════════════════════════

  factory AppException.fromError(dynamic error, [StackTrace? stackTrace]) {
    // Erreur réseau (timeout, pas de connexion)
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Connection timed out') ||
        error.toString().contains('Network is unreachable') ||
        error.toString().contains('Failed host lookup')) {
      return AppException(
        type: 'network',
        message: error.toString(),
        userMessage: 'Connexion instable. Vérifiez votre connexion internet.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Erreur Supabase PostgREST
    if (error.toString().contains('PostgrestError')) {
      final code = _extractPostgrestCode(error.toString());

      // RLS denial
      if (code == '42501' || error.toString().contains('permission denied')) {
        return AppException(
          type: 'permission',
          message: 'RLS denial: $error',
          userMessage: 'Accès refusé. Vérifiez vos permissions.',
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      // Duplicate key
      if (code == '23505') {
        return AppException(
          type: 'validation',
          message: 'Duplicate key: $error',
          userMessage: 'Cette donnée existe déjà. Veuillez vérifier.',
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      // Not found
      if (code == 'PGRST116' || code == '404') {
        return AppException(
          type: 'notFound',
          message: 'Not found: $error',
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      // JWT expired / auth
      if (code == 'PGRST301' || error.toString().contains('JWT')) {
        return AppException(
          type: 'auth',
          message: 'JWT expired: $error',
          userMessage: 'Votre session a expiré. Veuillez vous reconnecter.',
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      // Server error
      if (code.startsWith('5') ||
          error.toString().contains('Internal Server Error')) {
        return AppException(
          type: 'server',
          message: 'Server error: $error',
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      return AppException(
        type: 'validation',
        message: 'PostgREST error: $error',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Erreur inconnue
    return AppException(
      type: 'unknown',
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static String _extractPostgrestCode(String errorString) {
    final match = RegExp(r'code[:=]\s*"?([A-Z0-9]+)"?').firstMatch(errorString);
    return match?.group(1) ?? 'UNKNOWN';
  }
}
