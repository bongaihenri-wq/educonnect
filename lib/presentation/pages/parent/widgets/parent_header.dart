// lib/presentation/pages/parent/widgets/parent_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../blocs/auth_bloc/auth_bloc.dart';
import '../subscription_renewal_page.dart';

class ParentHeader extends StatelessWidget {
  const ParentHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! ParentAuthenticated) {
            return const SizedBox.shrink();
          }

          const bool showRenewButton = true;// Visible si proche expiration

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.violet.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Contenu principal : avatar + texte
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar parent
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initials(state.firstName, state.lastName),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.violet,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Nom + école + DURÉE RESTANTE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour,',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${state.firstName} ${state.lastName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.schoolName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.75),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // ✅ DURÉE RESTANTE REMISE
                            if (state.daysRemaining != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: state.daysRemaining! <= 3
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: state.daysRemaining! <= 3
                                      ? Border.all(color: Colors.white.withOpacity(0.3))
                                      : null,
                                ),
                                child: Text(
                                  state.daysRemaining! <= 0
                                      ? '⚠️ Abonnement expiré'
                                      : '⏳ ${state.daysRemaining} jours restants',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  // 🔘 Petit bouton rond Renouveler (coin haut-droit)
                  if (showRenewButton)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _navigateToRenewal(context, state),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: AppTheme.violet,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _initials(String? first, String? last) {
    final f = (first?.isNotEmpty ?? false) ? first![0].toUpperCase() : '';
    final l = (last?.isNotEmpty ?? false) ? last![0].toUpperCase() : '';
    return '$f$l';
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