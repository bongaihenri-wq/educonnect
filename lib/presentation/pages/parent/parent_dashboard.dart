// lib/presentation/pages/parent/parent_dashboard.dart
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
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

          return const Center(child: CircularProgressIndicator());
        },
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