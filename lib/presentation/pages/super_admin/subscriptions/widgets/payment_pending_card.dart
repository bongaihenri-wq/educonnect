// lib/presentation/pages/super_admin/subscriptions/widgets/payment_pending_card.dart
import 'package:flutter/material.dart';

class PaymentPendingCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onValidate;
  final VoidCallback onReject;

  const PaymentPendingCard({
    super.key,
    required this.payment,
    required this.onValidate,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ CORRIGÉ : app_users → parent, schools → school
    final parent = payment['parent'] is List ? (payment['parent'] as List).firstOrNull : payment['parent'];
    final school = payment['school'] is List ? (payment['school'] as List).firstOrNull : payment['school'];
    
    final parentName = '${parent?['first_name'] ?? ''} ${parent?['last_name'] ?? ''}';
    final parentPhone = parent?['phone'] ?? 'N/A';
    final schoolName = school?['name'] ?? 'École inconnue';
    final country = school?['country_code'] ?? ''; // ✅ CORRIGÉ : country → country_code
    final amount = payment['amount'] ?? 0;
    final reference = payment['external_ref'] ?? 'N/A'; // ✅ CORRIGÉ : reference → external_ref
    final paymentPhone = payment['payment_phone_number'] ?? 'N/A';
    final createdAt = payment['created_at'] != null
        ? DateTime.parse(payment['created_at'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFFE0B2), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8E1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending, color: Color(0xFFFF6D00), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'EN ATTENTE',
                        style: TextStyle(
                          color: Color(0xFFFF6D00),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF6B4EFF).withOpacity(0.15),
                  child: const Icon(Icons.person, color: Color(0xFF6B4EFF)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      Text(
                        '📱 $parentPhone',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.school, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  schoolName,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                if (country.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text(
                    country,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💰 ${_formatCurrency(amount)} XOF',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '📝 Réf: $reference',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '📲 Déposé depuis: $paymentPhone',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onValidate,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel, size: 20, color: Color(0xFFFF1744)),
                    label: const Text(
                      'Rejeter',
                      style: TextStyle(color: Color(0xFFFF1744)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF1744)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final value = amount is int ? amount : int.tryParse(amount.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}