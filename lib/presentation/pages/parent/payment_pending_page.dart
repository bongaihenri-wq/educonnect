// lib/presentation/pages/parent/payment_pending_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';

class PaymentPendingPage extends StatelessWidget {
  // ✅ CORRIGÉ : Aucun paramètre required, la page lit le state du Bloc
  const PaymentPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is ParentAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Paiement validé ! Accès réactivé.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
              // ✅ CORRIGÉ : Navigation via pushReplacementNamed au lieu de pushAndRemoveUntil
              Navigator.of(context).pushReplacementNamed('/parent/dashboard');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) {
              return _buildLoading();
            }

            if (state is PaymentSubmittedSuccessfully) {
              return _buildContent(context, state);
            }

            // Fallback si le state change vers autre chose
            return _buildLoading();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PaymentSubmittedSuccessfully state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hourglass_top, size: 48, color: Colors.orange[700]),
          ),
          const SizedBox(height: 24),
          Text(
            'Paiement en attente',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Votre soumission est en cours de validation par l\'administration de l\'école.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 32),

          // Carte d'infos
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildInfoRow(label: 'Référence', value: state.reference, isReference: true),
                const Divider(height: 24),
                _buildInfoRow(
                  label: 'Montant',
                  value: '${NumberFormat('#,##0').format(state.amount)} XOF',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  label: 'Date',
                  value: DateFormat('dd/MM/yyyy HH:mm').format(state.submittedAt),
                ),
                if (state.screenshotUrl != null) ...[
                  const Divider(height: 24),
                  const Text('Capture envoyée :', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      state.screenshotUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, __, ___) => Container(
                        height: 100,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Message info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vous recevrez une notification dès que votre paiement sera validé. Cela peut prendre quelques minutes.',
                    style: TextStyle(fontSize: 13, color: Colors.blue[800], height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Bouton vérifier
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(const CheckSubscriptionStatusRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Vérifier mon statut',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bouton déconnexion
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Vérification en cours...'),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isReference = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isReference ? FontWeight.w600 : FontWeight.normal,
              color: Colors.grey[900],
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: isReference ? 2 : 1,
          ),
        ),
      ],
    );
  }
}