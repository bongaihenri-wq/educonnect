// lib/presentation/pages/super_admin/subscriptions/widgets/history_payment_card.dart
import 'package:flutter/material.dart';

class HistoryPaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onArchive;

  const HistoryPaymentCard({
    super.key,
    required this.payment,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final parent = payment['parent'] as Map<String, dynamic>?;
    final school = payment['school'] as Map<String, dynamic>?;
    final validator = payment['validator'] as Map<String, dynamic>?;
    
    final parentName = parent != null 
        ? '${parent['first_name'] ?? ''} ${parent['last_name'] ?? ''}'.trim()
        : 'Parent inconnu';
    final schoolName = school?['name'] ?? '';
    final amount = payment['amount'] ?? 0;
    final currency = payment['currency'] ?? 'XOF';
    final status = payment['status'] ?? 'unknown';
    final externalRef = payment['external_ref'] ?? '';
    final createdAt = payment['created_at'] != null 
        ? DateTime.parse(payment['created_at'])
        : null;
    final verifiedAt = payment['verified_at'] != null 
        ? DateTime.parse(payment['verified_at'])
        : null;

    final isVerified = status == 'verified';
    final isRejected = status == 'rejected';

    return Dismissible(
      key: Key(payment['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.archive_outlined, color: Colors.white, size: 18),
            SizedBox(width: 4),
            Text('Archiver', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      onDismissed: (_) => onArchive(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isVerified 
                ? Colors.green.shade200 
                : isRejected 
                    ? Colors.red.shade200 
                    : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: InkWell(
          onTap: () {}, // Détail si besoin
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Statut indicator
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isVerified 
                        ? Colors.green 
                        : isRejected 
                            ? Colors.red 
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                
                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              parentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isVerified 
                                  ? Colors.green.shade50 
                                  : isRejected 
                                      ? Colors.red.shade50 
                                      : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isVerified ? 'VALIDÉ' : isRejected ? 'REJETÉ' : status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isVerified 
                                    ? Colors.green.shade700 
                                    : isRejected 
                                        ? Colors.red.shade700 
                                        : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$amount $currency',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          if (schoolName.isNotEmpty) ...[
                            Text(' · ', style: TextStyle(color: Colors.grey.shade400)),
                            Expanded(
                              child: Text(
                                schoolName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (externalRef.isNotEmpty)
                        Text(
                          'Ref: $externalRef',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                // Date + archive
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(verifiedAt ?? createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (validator != null)
                      Text(
                        'par ${validator['first_name']}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}