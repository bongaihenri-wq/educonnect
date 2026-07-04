import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'widgets/parent_header.dart';
import 'widgets/child_card.dart';
import 'widgets/alerts_section.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/logout_button.dart';
import 'widgets/subscription_warning_banner.dart';
import 'subscription_renewal_page.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is Unauthenticated,
      listener: (context, state) {
        // ✅ Redirection forcée vers le login quand déconnecté
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // ✅ Gérer le chargement pendant le logout
            if (state is AuthLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Déconnexion en cours...'),
                  ],
                ),
              );
            }

            // ✅ Gérer l'état déconnecté (sécurité)
            if (state is Unauthenticated) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Redirection vers la connexion...'),
                  ],
                ),
              );
            }

            if (state is ParentAuthenticated) {
              return CustomScrollView(
                slivers: [
                  // ✅ Bannière si abonnement expire bientôt
                  if (state.daysRemaining != null &&
                      state.daysRemaining! > 0 &&
                      state.daysRemaining! <= 3)
                    SubscriptionWarningBanner(
                      daysRemaining: state.daysRemaining!,
                      onRenew: () => _navigateToRenewal(context, state),
                    ),

                  // 🔒 CORRECTION : SafeArea + padding top pour éviter la barre de statut
                  SliverSafeArea(
                    sliver: SliverPadding(
                      padding: const EdgeInsets.only(top: 8),
                      sliver: const ParentHeader(),
                    ),
                  ),
                  const ChildCard(),
                  const AlertsSection(),
                  const QuickActionsGrid(),
                  const LogoutButton(),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                ],
              );
            }

            // État par défaut (chargement initial)
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
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