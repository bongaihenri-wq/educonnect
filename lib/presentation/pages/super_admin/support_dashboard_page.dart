// lib/presentation/pages/super_admin/support_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'parent_support_detail_page.dart';

class SupportDashboardPage extends StatefulWidget {
  const SupportDashboardPage({super.key});

  @override
  State<SupportDashboardPage> createState() => _SupportDashboardPageState();
}

class _SupportDashboardPageState extends State<SupportDashboardPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedParents = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  int _tmrMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final blocked = await _supabase.from('parents_blocked_view').select().limit(50);
      final pending = await _supabase.from('payments_pending_view').select().limit(50);

      setState(() {
        _blockedParents = List<Map<String, dynamic>>.from(blocked);
        _pendingPayments = List<Map<String, dynamic>>.from(pending);
        _tmrMinutes = 12;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Support Client'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiRow(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Parents bloqués (${_blockedParents.length})', Colors.red),
                    const SizedBox(height: 12),
                    _blockedParents.isEmpty
                        ? _buildEmptyState('Aucun parent bloqué', Icons.check_circle, Colors.green)
                        : _buildBlockedParentsList(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Paiements en attente (${_pendingPayments.length})', Colors.orange),
                    const SizedBox(height: 12),
                    _pendingPayments.isEmpty
                        ? _buildEmptyState('Aucun paiement en attente', Icons.check_circle, Colors.green)
                        : _buildPendingPaymentsList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKpiRow() {
    return Row(
      children: [
        Expanded(child: _buildKpiCard('Tickets', '${_blockedParents.length}', Icons.support_agent, const Color(0xFF6C63FF))),
        const SizedBox(width: 12),
        Expanded(child: _buildKpiCard('TMR', '$_tmrMinutes min', Icons.timer, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildKpiCard('Bloqués', '${_blockedParents.length}', Icons.block, Colors.red)),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildEmptyState(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBlockedParentsList() {
    return Column(
      children: _blockedParents.map((p) {
        final days = p['days_remaining'] as int?;
        final isExpired = days == null || days <= 0;
        final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}';
        final phone = p['phone'] ?? '—';
        final school = p['school_name'] ?? '—';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isExpired ? Colors.red : Colors.orange,
              child: Icon(isExpired ? Icons.block : Icons.access_time, color: Colors.white, size: 18),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$phone • $school', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                  isExpired ? 'Expiré${days != null && days < 0 ? ' depuis ${days.abs()}j' : ''}' : '$days jours restants',
                  style: TextStyle(fontSize: 12, color: isExpired ? Colors.red : Colors.orange, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6C63FF)),
            onTap: () => _openParentDetail(p['parent_id']?.toString() ?? ''),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPendingPaymentsList() {
    return Column(
      children: _pendingPayments.map((p) {
        final name = p['parent_name'] ?? '—';
        final ref = p['external_ref'] ?? '—';
        final amount = p['amount'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.15),
              child: const Icon(Icons.hourglass_top, color: Colors.orange, size: 18),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Réf: $ref • $amount XOF', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                  onPressed: () => _validatePayment(p['id'].toString()),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
                  onPressed: () => _rejectPayment(p['id'].toString()),
                ),
              ],
            ),
            onTap: () => _openParentDetail(p['parent_id']?.toString() ?? ''),
          ),
        );
      }).toList(),
    );
  }

  void _openParentDetail(String parentId) {
    if (parentId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ParentSupportDetailPage(parentId: parentId)),
    );
  }

  Future<void> _validatePayment(String paymentId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paiement validé ✅'), backgroundColor: Colors.green),
    );
    _loadData();
  }

  Future<void> _rejectPayment(String paymentId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paiement rejeté ❌'), backgroundColor: Colors.red),
    );
    _loadData();
  }
}