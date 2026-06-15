// lib/presentation/pages/parent/widgets/parent_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/presentation/blocs/auth_bloc/auth_bloc.dart';
import '../../../../config/theme.dart';
import '../subscription_renewal_page.dart';

class ParentHeader extends StatelessWidget {
  const ParentHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! ParentAuthenticated) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final String firstName = state.firstName;
        final String lastName = state.lastName;
        final String schoolName = state.schoolName;
        final String? subscriptionStatus = state.subscriptionStatus;
        final int? daysRemaining = state.daysRemaining;
        final int? amount = state.subscriptionAmount;
        final String? currency = state.subscriptionCurrency;
        final String? paymentPhone = state.paymentPhoneNumber;

        final bool isExpired = subscriptionStatus == 'expired' ||
            (daysRemaining != null && daysRemaining <= 0);

        final bool isExpiringSoon = !isExpired &&
            (subscriptionStatus == 'expiring_soon' ||
            (daysRemaining != null && daysRemaining > 0 && daysRemaining <= 3));

        final bool isActive = !isExpired && !isExpiringSoon &&
            (subscriptionStatus == 'active' || subscriptionStatus == 'trial');

        final bool isNoSub = subscriptionStatus == null ||
            subscriptionStatus == 'no_subscription';

        late final String statusLabel;
        late final Color statusColor;
        late final Color statusBg;
        late final IconData statusIcon;
        late final String? counterText;
        late final String buttonLabel;
        late final bool showButton;

        if (isExpired) {
          statusLabel = 'Abonnement expiré';
          statusColor = Colors.red;
          statusBg = Colors.red.withOpacity(0.15);
          statusIcon = Icons.error_outline;
          counterText = daysRemaining != null && daysRemaining < 0
              ? 'Depuis ${daysRemaining.abs()} jour${daysRemaining.abs() > 1 ? 's' : ''}'
              : null;
          buttonLabel = 'Réactiver';
          showButton = true;
        } else if (isExpiringSoon) {
          statusLabel = 'Expire bientôt';
          statusColor = Colors.orange;
          statusBg = Colors.orange.withOpacity(0.15);
          statusIcon = Icons.access_time;
          counterText = '$daysRemaining jour${daysRemaining! > 1 ? 's' : ''} restant${daysRemaining > 1 ? 's' : ''}';
          buttonLabel = 'Renouveler';
          showButton = true;
        } else if (isActive) {
          statusLabel = 'Abonnement actif';
          statusColor = Colors.green;
          statusBg = Colors.green.withOpacity(0.15);
          statusIcon = Icons.check_circle;
          counterText = daysRemaining != null
              ? '$daysRemaining jour${daysRemaining > 1 ? 's' : ''} restant${daysRemaining > 1 ? 's' : ''}'
              : null;
          buttonLabel = 'Renouveler';
          showButton = true;
        } else {
          statusLabel = 'Essai gratuit';
          statusColor = Colors.blue;
          statusBg = Colors.blue.withOpacity(0.15);
          statusIcon = Icons.card_giftcard;
          counterText = null;
          buttonLabel = 'S\'abonner';
          showButton = true;
        }

        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6), // ✅ Réduit
            padding: const EdgeInsets.all(16), // ✅ Réduit de 20 à 16
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(20), // ✅ Réduit
              boxShadow: [
                BoxShadow(
                  color: AppTheme.violet.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ligne titre + refresh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Espace Parents 💜',
                            style: TextStyle(
                              fontSize: 12, // ✅ Réduit
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2), // ✅ Réduit
                          Text(
                            '$firstName $lastName',
                            style: const TextStyle(
                              fontSize: 20, // ✅ Réduit de 24 à 20
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(const CheckSubscriptionStatusRequested());
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 20), // ✅ Réduit
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Actualiser',
                    ),
                  ],
                ),
                const SizedBox(height: 8), // ✅ Réduit
                // Badge école
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // ✅ Réduit
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    schoolName,
                    style: TextStyle(
                      fontSize: 12, // ✅ Réduit
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 12), // ✅ Réduit
                // ✅ Badge statut — compact
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // ✅ Réduit
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18), // ✅ Réduit
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // ✅ Réduit
                              ),
                            ),
                            if (counterText != null) ...[
                              const SizedBox(height: 1),
                              // ✅ COMPTEUR VISIBLE : blanc avec ombre légère
                              Text(
                                counterText,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95), // ✅ BLANC visible
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ✅ Bouton compact
                if (showButton) ...[
                  const SizedBox(height: 10), // ✅ Réduit
                  SizedBox(
                    width: double.infinity,
                    height: 40, // ✅ Hauteur fixe réduite
                    child: ElevatedButton(
                      onPressed: () => _navigateToRenewal(context, state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.violet,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 0), // ✅ Géré par height fixe
                      ),
                      child: Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13, // ✅ Réduit
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToRenewal(BuildContext context, ParentAuthenticated state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionRenewalPage(
          parentId: state.userId,
          schoolId: state.schoolId,
          amount: state.subscriptionAmount ?? 1000,
          currency: state.subscriptionCurrency ?? 'XOF',
          paymentPhoneNumber: state.paymentPhoneNumber,
          currentStatus: state.subscriptionStatus,
          currentEndDate: state.subscriptionEndDate,
          daysRemaining: state.daysRemaining,
        ),
      ),
    );
  }
}