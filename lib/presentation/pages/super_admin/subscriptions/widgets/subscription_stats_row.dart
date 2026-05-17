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
    final totalParents = stats['total_parents'] ?? 0;
    final monthlyRevenue = stats['monthly_revenue'] ?? 0;
    final pendingPayments = stats['pending_payments'] ?? 0;
    final expiredCount = stats['expired_subscriptions'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3.0, // ✅ TRÈS LARGE pour éviter tout overflow
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
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
          icon: Icons.pending,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}