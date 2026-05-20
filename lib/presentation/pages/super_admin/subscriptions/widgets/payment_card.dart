// lib/presentation/pages/super_admin/subscriptions/widgets/payment_card.dart
import 'package:flutter/material.dart';
import 'detail_row.dart';

class PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onValidate;
  final VoidCallback onReject;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.onValidate,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final parent = payment['parent'] as Map<String, dynamic>?;
    final school = payment['school'] as Map<String, dynamic>?;
    
    final parentName = parent != null 
        ? '${parent['first_name'] ?? ''} ${parent['last_name'] ?? ''}'.trim()
        : 'Parent inconnu';
    final parentPhone = parent?['phone'] ?? 'N/A';
    final schoolName = school?['name'] ?? 'École inconnue';
    final amount = payment['amount'] ?? 0;
    final currency = payment['currency'] ?? 'XOF';
    final provider = payment['provider'] ?? 'N/A';
    final externalRef = payment['external_ref'] ?? 'N/A';
    final createdAt = payment['created_at'] != null 
        ? DateTime.parse(payment['created_at'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(createdAt),
              const SizedBox(height: 12),
              _buildParentInfo(parentName, parentPhone),
              const SizedBox(height: 12),
              _buildPaymentDetails(amount, currency, schoolName, provider, externalRef),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime? createdAt) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.orange.shade800),
              const SizedBox(width: 4),
              Text(
                'EN ATTENTE',
                style: TextStyle(
                  color: Colors.orange.shade800,
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
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildParentInfo(String parentName, String parentPhone) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF6B4EFF),
          child: Text(
            parentName.isNotEmpty ? parentName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
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
                ),
              ),
              Text(
                '📱 $parentPhone',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails(int amount, String currency, String schoolName, String provider, String externalRef) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          DetailRow(label: '💰 Montant', value: '$amount $currency'),
          const SizedBox(height: 6),
          DetailRow(label: '🏫 École', value: schoolName),
          const SizedBox(height: 6),
          DetailRow(label: '💳 Provider', value: provider.toUpperCase()),
          const SizedBox(height: 6),
          DetailRow(label: '🔖 Référence', value: externalRef, isReference: true),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onValidate,
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('VALIDER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
            label: const Text('REJETER', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}