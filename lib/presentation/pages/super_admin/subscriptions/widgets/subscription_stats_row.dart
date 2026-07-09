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
    print('📊 STATS REÇUES: $stats');
    print('📊 CLÉS: ${stats.keys.toList()}');

    final totalParents = _getStatValue([
      'total_parents',
      'totalParents',
      'parents_count',
      'count',
      'active_parents',
      'total_active_parents'
    ]);
    final monthlyRevenue = _getStatValue([
      'monthly_revenue',
      'monthlyRevenue',
      'revenue',
      'total_revenue',
      'total_amount_paid',
      'total_paid'
    ]);
    final pendingPayments = _getStatValue([
      'pending_payments',
      'pendingPayments',
      'pending_count',
      'en_attente',
      'payments_pending',
      'count_pending'
    ]);
    final expiredCount = _getStatValue([
      'expired_subscriptions',
      'expiredSubscriptions',
      'expired_count',
      'expirés',
      'subscriptions_expired',
      'count_expired'
    ]);

    print(
        '📊 VALEURS: parents=$totalParents, revenue=$monthlyRevenue, pending=$pendingPayments, expired=$expiredCount');

    // ✅ CORRIGÉ : Wrap au lieu de GridView → pas de dépassement
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: _StatItem(
            icon: Icons.people,
            color: const Color(0xFF6B4EFF),
            label: 'Parents',
            value: totalParents.toString(),
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: _StatItem(
            icon: Icons.attach_money,
            color: const Color(0xFF00C853),
            label: 'Revenus',
            value: '${_formatNumber(monthlyRevenue)} XOF',
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: _StatItem(
            icon: Icons.pending_actions,
            color: const Color(0xFFFF6D00),
            label: 'En attente',
            value: pendingPayments.toString(),
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: _StatItem(
            icon: Icons.error_outline,
            color: const Color(0xFFFF1744),
            label: 'Expirés',
            value: expiredCount.toString(),
          ),
        ),
      ],
    );
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
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
