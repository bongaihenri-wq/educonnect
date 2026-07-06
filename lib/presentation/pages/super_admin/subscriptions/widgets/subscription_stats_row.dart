// lib/presentation/pages/super_admin/subscriptions/widgets/subscription_stats_row.dart
import 'package:flutter/material.dart';

class SubscriptionStatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;

  const SubscriptionStatsRow({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ DEBUG : Afficher les clés reçues dans la console
    print('📊 STATS REÇUES DANS WIDGET: $stats');
    print('📊 CLÉS DISPONIBLES: ${stats.keys.toList()}');

    // ✅ Données réelles avec fallback sur les clés possibles
    // (car la fonction RPC peut retourner des noms différents)
    final totalParents = _getStatValue(
        ['total_parents', 'totalParents', 'parents_count', 'count']);
    final monthlyRevenue = _getStatValue(
        ['monthly_revenue', 'monthlyRevenue', 'revenue', 'total_revenue']);
    final pendingPayments = _getStatValue(
        ['pending_payments', 'pendingPayments', 'pending_count', 'en_attente']);
    final expiredCount = _getStatValue([
      'expired_subscriptions',
      'expiredSubscriptions',
      'expired_count',
      'expirés'
    ]);

    print(
        '📊 VALEURS EXTRAITES: parents=$totalParents, revenue=$monthlyRevenue, pending=$pendingPayments, expired=$expiredCount');

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _StatItem(
          icon: Icons.people,
          color: const Color(0xFF6B4EFF),
          label: 'Parents',
          value: totalParents.toString(),
        ),
        _StatItem(
          icon: Icons.attach_money,
          color: const Color(0xFF00C853),
          label: 'Revenus',
          value: '${_formatNumber(monthlyRevenue)} XOF',
        ),
        _StatItem(
          icon: Icons.pending_actions,
          color: const Color(0xFFFF6D00),
          label: 'En attente',
          value: pendingPayments.toString(),
        ),
        _StatItem(
          icon: Icons.error_outline,
          color: const Color(0xFFFF1744),
          label: 'Expirés',
          value: expiredCount.toString(),
        ),
      ],
    );
  }

  // ✅ Helper : Cherche la valeur dans plusieurs clés possibles
  dynamic _getStatValue(List<String> possibleKeys) {
    for (final key in possibleKeys) {
      if (stats.containsKey(key) && stats[key] != null) {
        return stats[key];
      }
    }
    return 0;
  }

  String _formatNumber(dynamic n) {
    if (n == null) return '0';
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
