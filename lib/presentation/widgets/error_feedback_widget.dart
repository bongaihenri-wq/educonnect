// lib/presentation/widgets/error_feedback_widget.dart
import 'package:flutter/material.dart';
import '../../core/exceptions/app_exception.dart';

/// Widget affiché quand une erreur réseau/serveur survient.
///
/// EFFET RÉEL : Remplace l'écran blanc/crash par un message clair
/// avec un bouton "Réessayer" et un indicateur de retry auto.
///
/// UTILISÉ DANS :
/// - AlertsSection (quand _loadData échoue)
/// - ChildCard (quand chargement échoue)
/// - GradesTab (quand notes échouent)
/// - HomeworkTab (quand devoirs échouent)
/// - Toutes les pages avec chargement de données
class ErrorFeedbackWidget extends StatelessWidget {
  final AppException? error;
  final VoidCallback? onRetry;
  final bool isRetrying;
  final int? retryAttempt;
  final Duration? nextRetryDelay;

  const ErrorFeedbackWidget({
    super.key,
    this.error,
    this.onRetry,
    this.isRetrying = false,
    this.retryAttempt,
    this.nextRetryDelay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône selon le type d'erreur
            _buildIcon(),
            const SizedBox(height: 20),

            // Titre
            Text(
              _getTitle(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message utilisateur (jamais technique)
            Text(
              error?.displayMessage ?? 'Une erreur est survenue.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Info retry (si en cours)
            if (isRetrying && retryAttempt != null) ...[
              Text(
                'Tentative $retryAttempt/${retryAttempt! + 1}...',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ),
              if (nextRetryDelay != null)
                Text(
                  'Nouvelle tentative dans ${nextRetryDelay!.inSeconds}s',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(strokeWidth: 2),
            ],

            const SizedBox(height: 20),

            // Bouton réessayer (si pas en retry auto)
            if (!isRetrying && onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final IconData iconData;
    final Color color;

    switch (error?.type) {
      case 'network':
        iconData = Icons.wifi_off;
        color = Colors.orange;
        break;
      case 'server':
        iconData = Icons.cloud_off;
        color = Colors.red;
        break;
      case 'auth':
        iconData = Icons.lock;
        color = Colors.purple;
        break;
      case 'permission':
        iconData = Icons.block;
        color = Colors.red;
        break;
      default:
        iconData = Icons.error_outline;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 48, color: color),
    );
  }

  String _getTitle() {
    switch (error?.type) {
      case 'network':
        return 'Connexion instable';
      case 'server':
        return 'Serveur indisponible';
      case 'auth':
        return 'Session expirée';
      case 'permission':
        return 'Accès refusé';
      default:
        return 'Erreur';
    }
  }
}
