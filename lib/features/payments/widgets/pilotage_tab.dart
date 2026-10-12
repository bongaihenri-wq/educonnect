import 'package:flutter/material.dart';
import '../utils/payment_formatters.dart';
import 'stat_card.dart';

class PilotageTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> history;
  final bool loading;
  final Future<void> Function() onRefresh;

  const PilotageTab({
    super.key,
    required this.stats,
    required this.history,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final total = stats['total'] as int? ?? 0;
    final ok = stats['upToDate'] as int? ?? 0;
    final late = stats['late'] as int? ?? 0;
    final remaining = stats['remaining'] as double? ?? 0;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatCard(
                    label: 'Élèves suivis',
                    value: '$total',
                    color: Colors.blue.shade700),
                StatCard(
                    label: 'À jour',
                    value: '$ok',
                    color: Colors.green.shade700),
                StatCard(
                    label: 'En retard',
                    value: '$late',
                    color: Colors.red.shade700),
                StatCard(
                    label: 'Reste global dû',
                    value: '${PaymentFormatters.fmt(remaining)} F',
                    color: remaining > 0
                        ? Colors.orange.shade800
                        : Colors.green.shade700),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Importer un fichier de paiements'),
              onPressed: () => Navigator.pushNamed(context, '/admin/payments'),
            ),
            const SizedBox(height: 16),
            if (history.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.history, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  const Text('Historique des imports',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              ...history.map((h) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                    PaymentFormatters.fmtDateTime(
                                        h['created_at']),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if ((h['rejected_rows'] as int? ?? 0) > 0)
                                Text('${h['rejected_rows']} rejetée(s)',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text(
                                  '${h['accepted_rows']}/${h['total_rows']} lignes',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700)),
                              Text('✅ ${h['up_to_date_count'] ?? 0} à jour',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600)),
                              Text('⚠️ ${h['late_count'] ?? 0} en retard',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
