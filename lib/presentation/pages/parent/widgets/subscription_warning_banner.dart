// lib/presentation/pages/parent/widgets/subscription_warning_banner.dart
import 'package:flutter/material.dart';

class SubscriptionWarningBanner extends StatelessWidget {
  final int daysRemaining;
  final VoidCallback onRenew;

  const SubscriptionWarningBanner({
    super.key,
    required this.daysRemaining,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCritical = daysRemaining <= 1;
    final Color bgColor = isCritical ? Colors.red[50]! : Colors.orange[50]!;
    final Color borderColor = isCritical ? Colors.red[200]! : Colors.orange[200]!;
    final Color textColor = isCritical ? Colors.red[800]! : Colors.orange[800]!;
    final Color buttonColor = isCritical ? Colors.red[700]! : Colors.orange[700]!;
    final IconData icon = isCritical ? Icons.error_outline : Icons.access_time;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: textColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCritical
                        ? 'Votre abonnement expire demain !'
                        : 'Votre abonnement expire dans $daysRemaining jours',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Renouvelez maintenant pour ne pas perdre l\'accès aux informations de votre enfant.',
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRenew,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Renouveler maintenant',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}