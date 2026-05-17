// lib/presentation/pages/parent/payment_pending_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';

class PaymentPendingPage extends StatelessWidget {
  final String reference;
  final double amount;

  const PaymentPendingPage({
    super.key,
    required this.reference,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B4EFF), Color(0xFF9B7BFF), Colors.white],
            stops: [0.0, 0.4, 0.8],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(  // ✅ AJOUTÉ : Pour éviter overflow vertical
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // ⏳ Animation d'attente
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // ✅ Message de confirmation
                const Text(
                  'Demande envoyée !',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // 📋 Détails
                Container(
                  width: double.infinity,  // ✅ AJOUTÉ : Prend toute la largeur
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Référence:', reference),
                      const SizedBox(height: 8),
                      _buildDetailRow('Montant:', '${amount.toInt()} XOF'),
                      const SizedBox(height: 8),
                      _buildDetailRow('Statut:', '⏳ En attente'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ℹ️ Instructions
                Container(
                  width: double.infinity,  // ✅ AJOUTÉ
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Color(0xFFFFB300)),
                      SizedBox(width: 12),
                      Expanded(  // ✅ DÉJÀ LÀ : Empêche overflow
                        child: Text(
                          'Votre paiement est en cours de vérification. Vous recevrez une notification dès que votre accès sera réactivé.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D3142),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 🔄 Bouton retour login
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(const LogoutRequested());
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Retour à la connexion',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6B4EFF),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ CORRIGÉ : Utilise Wrap au lieu de Row pour éviter l'overflow
  Widget _buildDetailRow(String label, String value) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,  // ✅ Sécurité supplémentaire
        ),
      ],
    );
  }
}