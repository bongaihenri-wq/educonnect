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
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.violet.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          fontSize: 14,
                          color: AppTheme.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is ParentAuthenticated) {
                            return Text(
                              '${state.firstName} ${state.lastName}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return const Text(
                            'Espace Parent',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // ⭐ NOUVEAU : Bouton Actualiser
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is ParentAuthenticated) {
                          return IconButton(
                            icon: const Icon(Icons.refresh, color: AppTheme.white),
                            onPressed: () {
                              // Recharger les données en émettant AppStarted
                              context.read<AuthBloc>().add(const AppStarted());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🔄 Actualisation...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            tooltip: 'Actualiser',
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    // Menu abonnement
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is ParentAuthenticated) {
                          return _buildSubscriptionMenu(context, state);
                        }
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: AppTheme.white,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                String schoolName = 'Mon École';
                String childInfo = 'Enfant suivi';
                
                if (state is ParentAuthenticated) {
                  schoolName = state.schoolName;
                  childInfo = '${state.studentName} - ${state.className}';
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoChip(
                      icon: Icons.school,
                      text: schoolName,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoChip(
                      icon: Icons.child_care,
                      text: childInfo,
                      opacity: 0.15,
                    ),
                  ],
                );
              },
            ),
            // ⭐ NOUVEAU : Affichage subscription status
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is ParentAuthenticated) {
                  return _buildSubscriptionStatus(state);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatus(ParentAuthenticated state) {
    final status = state.subscriptionStatus ?? 'no_subscription';
    final daysRemaining = state.daysRemaining ?? 0;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'active':
        if (daysRemaining <= 7) {
          statusColor = Colors.orange;
          statusIcon = Icons.access_time;
          statusText = 'Expire dans $daysRemaining jours';
        } else {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          statusText = '$daysRemaining jours restants';
        }
        break;
      case 'trial':
        statusColor = Colors.blue;
        statusIcon = Icons.new_releases;
        statusText = 'Essai: $daysRemaining jours';
        break;
      case 'expired':
      case 'no_subscription':
      default:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        statusText = 'Abonnement expiré';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.95),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionMenu(BuildContext context, ParentAuthenticated state) {
    final status = state.subscriptionStatus ?? 'no_subscription';
    final daysRemaining = state.daysRemaining ?? 0;
    
    Color badgeColor;
    IconData badgeIcon;
    
    switch (status) {
      case 'active':
        if (daysRemaining <= 7) {
          badgeColor = Colors.orange;
          badgeIcon = Icons.access_time;
        } else {
          badgeColor = Colors.green;
          badgeIcon = Icons.check_circle;
        }
        break;
      case 'trial':
        badgeColor = Colors.blue;
        badgeIcon = Icons.new_releases;
        break;
      default:
        badgeColor = Colors.red;
        badgeIcon = Icons.warning;
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu,
              color: AppTheme.white,
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.violet, width: 2),
              ),
              child: Icon(
                badgeIcon,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ],
      ),
      onSelected: (value) {
        if (value == 'subscription') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubscriptionRenewalPage(
                parentId: state.userId,
                schoolId: state.schoolId,
                currentStatus: state.subscriptionStatus,
                currentEndDate: state.subscriptionEndDate,
                daysRemaining: state.daysRemaining,
                amount: state.subscriptionAmount ?? 1000,
                currency: state.subscriptionCurrency ?? 'XOF',
                paymentPhoneNumber: state.paymentPhoneNumber,
              ),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'subscription',
          child: Row(
            children: [
              Icon(badgeIcon, color: badgeColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon Abonnement',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      status == 'active' 
                          ? '$daysRemaining jours restants'
                          : status == 'trial'
                              ? 'Essai: $daysRemaining jours'
                              : 'Renouveler maintenant',
                      style: TextStyle(
                        fontSize: 12,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'profile',
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
              Text(
                'Profil',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    double opacity = 0.2,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.white, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.white.withOpacity(0.95),
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}