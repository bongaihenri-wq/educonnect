// lib/core/services/retry_service.dart
import 'dart:async';
import 'dart:math';
import 'package:educonnect/core/exceptions/app_exception.dart';

/// Service de retry avec backoff exponentiel.
///
/// EFFET RÉEL : Quand une requête échoue (timeout 3G),
/// l'app réessaie automatiquement 3 fois avec des délais croissants
/// (1s → 2s → 4s) au lieu d'abandonner immédiatement.
///
/// SCÉNARIO : Enseignant fait l'appel en classe, réseau 3G instable.
/// Avant : Upsert échoue → 30 absences perdues → appel à refaire
/// Après : Retry auto ×3 → succès probable → appel sauvé
class RetryService {
  final int maxRetries;
  final Duration baseDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryService({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 10),
  });

  /// Exécute une opération avec retry automatique.
  ///
  /// [operation] : La fonction à exécuter (ex: requête Supabase)
  /// [shouldRetry] : Fonction optionnelle pour décider si on retry
  ///
  /// Retourne le résultat de [operation] ou lance [AppException] finale.
  Future<T> execute<T>(
    Future<T> Function() operation, {
    bool Function(AppException)? shouldRetry,
  }) async {
    int attempt = 0;
    AppException? lastError;

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        final appException = AppException.fromError(e, stackTrace);
        lastError = appException;

        // Si c'est la dernière tentative, on abandonne
        if (attempt >= maxRetries) break;

        // Si l'erreur n'est pas retryable, on abandonne immédiatement
        if (!appException.isRetryable) break;

        // Si shouldRetry est fourni et dit non, on abandonne
        if (shouldRetry != null && !shouldRetry(appException)) break;

        // Calcul du délai avec backoff exponentiel + jitter
        final delay = _calculateDelay(attempt);

        // Attente avant retry
        await Future.delayed(delay);

        attempt++;
      }
    }

    // Toutes les tentatives ont échoué
    throw lastError!;
  }

  /// Calcule le délai avant retry avec backoff exponentiel + jitter.
  ///
  /// Formule : baseDelay × (multiplier ^ attempt) + jitter
  /// Jitter = random(0, baseDelay) pour éviter les thundering herds
  Duration _calculateDelay(int attempt) {
    final exponentialDelay =
        baseDelay.inMilliseconds * pow(backoffMultiplier, attempt).toInt();
    final jitter = Random().nextInt(baseDelay.inMilliseconds);
    final totalMs = min(exponentialDelay + jitter, maxDelay.inMilliseconds);

    return Duration(milliseconds: totalMs);
  }

  /// Version simplifiée pour les widgets (avec callback onRetry).
  ///
  /// [onRetry] : Callback appelé à chaque tentative (pour UI loading)
  Future<T> executeWithCallback<T>(
    Future<T> Function() operation, {
    required void Function(int attempt, Duration nextDelay) onRetry,
    bool Function(AppException)? shouldRetry,
  }) async {
    int attempt = 0;

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        final appException = AppException.fromError(e, stackTrace);

        if (attempt >= maxRetries) throw appException;
        if (!appException.isRetryable) throw appException;
        if (shouldRetry != null && !shouldRetry(appException)) {
          throw appException;
        }

        final delay = _calculateDelay(attempt);
        onRetry(attempt + 1, delay);
        await Future.delayed(delay);

        attempt++;
      }
    }

    throw AppException(
      type: 'unknown',
      message: 'Max retries exceeded',
      userMessage: 'Impossible de se connecter après plusieurs tentatives.',
    );
  }
}

/// Instance globale du service de retry
const retryService = RetryService();
