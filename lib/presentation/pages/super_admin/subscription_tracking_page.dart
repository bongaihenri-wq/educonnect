import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SubscriptionTrackingPage extends StatefulWidget {
  const SubscriptionTrackingPage({super.key});

  @override
  State<SubscriptionTrackingPage> createState() => _SubscriptionTrackingPageState();
}

class _SubscriptionTrackingPageState extends State<SubscriptionTrackingPage> {
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _schools = [];
  String? _selectedSchoolId;
  String _selectedStatus = 'all';
  String _selectedMonth = '';
  bool _isLoading = true;

  final List<String> _statuses = ['all', 'pending', 'paid', 'late', 'cancelled'];
  final List<String> _months = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = _getCurrentMonth();
    _generateMonths();
    _loadData();
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void _generateMonths() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      _months.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final schoolsResponse = await supabase.from('schools').select('id, name').order('name');
      _schools = List<Map<String, dynamic>>.from(schoolsResponse);

      var query = supabase.from('subscriptions').select('''
        *,
        schools:school_id(name),
        parents:parent_id(first_name, last_name, phone),
        students:student_id(first_name, last_name, matricule)
      ''').eq('month', _selectedMonth);

      if (_selectedSchoolId != null) {
        query = query.eq('school_id', _selectedSchoolId!);
      }

      if (_selectedStatus != 'all') {
        query = query.eq('status', _selectedStatus);
      }

      final response = await query.order('created_at', ascending: false);
      setState(() {
        _subscriptions = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des Paiements'),
        backgroundColor: const Color(0xFF6B4EFF),
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildQuickStats(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _subscriptions.isEmpty
                    ? _buildEmptyState()
                    : _buildSubscriptionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSchoolId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'École',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toutes les écoles')),
                    ..._schools.map((s) => DropdownMenuItem(
                      value: s['id'] as String,
                      child: Text(s['name'] ?? 'Sans nom', overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedSchoolId = v);
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mois',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) {
                    setState(() => _selectedMonth = v!);
                    _loadData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((status) {
                final isSelected = _selectedStatus == status;
                final color = _getStatusColor(status);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: color.withOpacity(0.1),
                    onSelected: (_) {
                      setState(() => _selectedStatus = status);
                      _loadData();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final total = _subscriptions.length;
    final paid = _subscriptions.where((s) => s['status'] == 'paid').length;
    final pending = _subscriptions.where((s) => s['status'] == 'pending').length;
    final late = _subscriptions.where((s) => s['status'] == 'late').length;
    final totalAmount = _subscriptions
        .where((s) => s['status'] == 'paid')
        .fold<double>(0, (sum, s) => sum + ((s['amount'] ?? 0) as num).toDouble());

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _QuickStat(label: 'Total', value: '$total', color: Colors.blue),
          _QuickStat(label: 'Payés', value: '$paid', color: Colors.green),
          _QuickStat(label: 'En attente', value: '$pending', color: Colors.orange),
          _QuickStat(label: 'En retard', value: '$late', color: Colors.red),
          _QuickStat(label: 'Montant', value: '${totalAmount.toStringAsFixed(0)} XOF', color: Colors.purple),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun paiement trouvé',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subscriptions.length,
      itemBuilder: (context, index) {
        final sub = _subscriptions[index];
        return _SubscriptionCard(subscription: sub);
      },
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'all': return 'Tous';
      case 'pending': return 'En attente';
      case 'paid': return 'Payé';
      case 'late': return 'En retard';
      case 'cancelled': return 'Annulé';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'all': return Colors.grey;
      case 'pending': return Colors.orange;
      case 'paid': return Colors.green;
      case 'late': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.blue;
    }
  }
}

// ==================== SUBSCRIPTION CARD ====================

class _SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> subscription;

  const _SubscriptionCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final status = subscription['status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status);
    final school = subscription['schools'] as Map<String, dynamic>?;
    final parent = subscription['parents'] as Map<String, dynamic>?;
    final student = subscription['students'] as Map<String, dynamic>?;
    final amount = (subscription['amount'] ?? 0) as num;
    final paymentMethod = subscription['payment_method'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${amount.toStringAsFixed(0)} XOF',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              school?['name'] ?? 'École inconnue',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${parent?['first_name'] ?? ''} ${parent?['last_name'] ?? ''}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.school, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Élève: ${student?['first_name'] ?? ''} ${student?['last_name'] ?? ''} (${student?['matricule'] ?? '---'})',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            if (paymentMethod != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Méthode: ${_getPaymentMethodLabel(paymentMethod)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Mois: ${subscription['month'] ?? '---'}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'paid': return Colors.green;
      case 'late': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.blue;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'orange_money': return 'Orange Money';
      case 'mtn_momo': return 'MTN MoMo';
      case 'wave': return 'Wave';
      case 'tmoney': return 'T-Money';
      default: return method;
    }
  }
}

// ==================== QUICK STAT ====================

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}