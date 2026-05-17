// lib/presentation/pages/super_admin/subscriptions/tabs/payments_tab.dart
import 'package:flutter/material.dart';
import '../widgets/payment_card.dart';
import '../widgets/history_payment_card.dart';

class PaymentsTab extends StatefulWidget {
  final List<Map<String, dynamic>> pendingPayments;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String) onValidate;
  final Future<void> Function(String) onReject;
  final Future<List<Map<String, dynamic>>> Function({String? status, bool includeArchived}) getHistory;
  final Future<void> Function(String) onArchive;

  const PaymentsTab({
    super.key,
    required this.pendingPayments,
    required this.onRefresh,
    required this.onValidate,
    required this.onReject,
    required this.getHistory,
    required this.onArchive,
  });

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  String _filterStatus = 'pending'; // pending, verified, rejected, all
  List<Map<String, dynamic>> _history = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await widget.getHistory(
        status: _filterStatus == 'all' ? null : _filterStatus,
        includeArchived: false,
      );
      setState(() {
        _history = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.pendingPayments.length;

    return Column(
      children: [
        // Filtres horizontaux fins
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('pending', '⏳ En attente', pendingCount),
              _buildFilterChip('verified', '✅ Validés', null),
              _buildFilterChip('rejected', '❌ Rejetés', null),
              _buildFilterChip('all', '📋 Tous', null),
            ],
          ),
        ),

        // Liste
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await widget.onRefresh();
              await _loadHistory();
            },
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _buildList(pendingCount),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, int? count) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _filterStatus = value);
            _loadHistory();
          }
        },
        selectedColor: const Color(0xFF6B4EFF).withOpacity(0.15),
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildList(int pendingCount) {
    if (_filterStatus == 'pending') {
      // Afficher les pending en haut + historique pending
      if (widget.pendingPayments.isEmpty) {
        return _buildEmptyState('Aucun paiement en attente');
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.pendingPayments.length,
        itemBuilder: (context, index) {
          if (index == 0 && pendingCount > 0) {
            return Column(
              children: [
                _buildAlertBanner(pendingCount),
                PaymentCard(
                  payment: widget.pendingPayments[index],
                  onValidate: () => widget.onValidate(widget.pendingPayments[index]['id']),
                  onReject: () => widget.onReject(widget.pendingPayments[index]['id']),
                ),
              ],
            );
          }
          return PaymentCard(
            payment: widget.pendingPayments[index],
            onValidate: () => widget.onValidate(widget.pendingPayments[index]['id']),
            onReject: () => widget.onReject(widget.pendingPayments[index]['id']),
          );
        },
      );
    }

    // Historique (verified, rejected, all)
    if (_history.isEmpty) {
      return _buildEmptyState('Aucun historique');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        return HistoryPaymentCard(
          payment: _history[index],
          onArchive: () => _archivePayment(_history[index]['id']),
        );
      },
    );
  }

  Widget _buildAlertBanner(int count) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count en attente de validation',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _archivePayment(String transactionId) async {
    try {
      await widget.onArchive(transactionId);
      _loadHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Paiement archivé'),
          backgroundColor: Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}