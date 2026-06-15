// lib/presentation/pages/super_admin/payment_validation_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentValidationPage extends StatefulWidget {
  const PaymentValidationPage({super.key});

  @override
  State<PaymentValidationPage> createState() => _PaymentValidationPageState();
}

class _PaymentValidationPageState extends State<PaymentValidationPage> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('payment_transactions')
          .select('*, app_users(first_name, last_name, phone), schools(name)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      setState(() {
        _payments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement paiements: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _validate(String transactionId) async {
    try {
      await Supabase.instance.client.rpc('validate_payment', params: {
        'p_transaction_id': transactionId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement validé avec succès'), backgroundColor: Colors.green),
      );
      _loadPayments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reject(String transactionId) async {
    try {
      await Supabase.instance.client.rpc('reject_payment', params: {
        'p_transaction_id': transactionId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement rejeté'), backgroundColor: Colors.orange),
      );
      _loadPayments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showImage(String? url) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Validation des paiements'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun paiement en attente',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final p = _payments[index];
                    final user = p['app_users'] ?? {};
                    final school = p['schools'] ?? {};
                    final hasScreenshot = p['screenshot_url'] != null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                                  child: Text(
                                    '${user['first_name']?[0] ?? ''}${user['last_name']?[0] ?? ''}',
                                    style: const TextStyle(
                                      color: Color(0xFF6C63FF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${user['phone'] ?? ''} • ${school['name'] ?? 'École inconnue'}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'En attente',
                                    style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfo('Référence', p['external_ref'] ?? '-'),
                                _buildInfo('Montant', '${p['amount']} ${p['currency']}'),
                                _buildInfo('Date', _formatDate(p['created_at'])),
                              ],
                            ),
                            if (hasScreenshot) ...[
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => _showImage(p['screenshot_url']),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    p['screenshot_url'],
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => _showImage(p['screenshot_url']),
                                  icon: const Icon(Icons.zoom_in, size: 18),
                                  label: const Text('Voir en grand'),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _validate(p['id']),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Valider'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _reject(p['id']),
                                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                    label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}