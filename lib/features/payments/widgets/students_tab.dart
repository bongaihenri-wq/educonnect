import 'package:educonnect/features/payments/widgets/payment_tab_events.dart';
import 'package:flutter/material.dart';
import '../data/payment_repository.dart';
import '../models/payment_status_dto.dart';
import '../utils/payment_formatters.dart';
import 'add_payment_dialog.dart';

class StudentsTab extends StatefulWidget {
  final PaymentRepository repo;
  final String schoolId;
  final List<PaymentStatusDto> statuses;
  final bool loading;

  const StudentsTab({
    super.key,
    required this.repo,
    required this.schoolId,
    required this.statuses,
    required this.loading,
  });

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
        () => setState(() => _search = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PaymentStatusDto> get _filtered => _search.isEmpty
      ? widget.statuses
      : widget.statuses
          .where((s) =>
              s.studentName.toLowerCase().contains(_search) ||
              s.matricule.toLowerCase().contains(_search))
          .toList();

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtered = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un élève ou un matricule...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _searchController.clear),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Aucun élève — importez un fichier'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _buildStudentTile(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildStudentTile(PaymentStatusDto s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor:
              s.isUpToDate ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            s.isUpToDate ? Icons.check : Icons.warning_amber,
            color: s.isUpToDate ? Colors.green : Colors.red,
            size: 18,
          ),
        ),
        title: Text(s.studentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Wrap(children: [
          Text(
              '${s.matricule} · Reste dû : ${PaymentFormatters.fmt(s.remaining)} F',
              style: const TextStyle(fontSize: 12)),
          if (s.contested)
            Text('  ·  ⚠️ Contesté',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold)),
        ]),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 22),
          tooltip: 'Ajouter un versement',
          color: Colors.green.shade700,
          onPressed: () => _addPayment(s),
        ),
        onTap: () => _showStudentDetail(s),
      ),
    );
  }

  Future<void> _addPayment(PaymentStatusDto s) async {
    final done =
        await showAddPaymentDialog(context, widget.repo, widget.schoolId, s);
    if (done && mounted) {
      // Notifie la page parente de recharger
      PaymentTabEvents.instance.notifyChanged();
    }
  }

  Future<void> _showStudentDetail(PaymentStatusDto s) async {
    final lines = await widget.repo.getStudentLinesAdmin(s.studentId);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.studentName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(s.matricule, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            if (lines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Aucun paiement enregistré',
                    textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: lines.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final l = lines[i];
                    final paid = (l['amount_paid'] as num?)?.toDouble() ?? 0;
                    final due = (l['amount_due'] as num?)?.toDouble() ?? 0;
                    final isManual = l['source'] == 'manual';
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        paid >= due && due > 0
                            ? Icons.check_circle_outline
                            : Icons.schedule,
                        color: paid >= due && due > 0
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                      title: Text(l['libelle'] ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${PaymentFormatters.fmt(paid)} / ${PaymentFormatters.fmt(due)} F · ${l['periode']}'
                        '${isManual ? ' · saisi manuellement' : ''}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        l['paid_at'] != null
                            ? (l['paid_at'] as String).substring(0, 10)
                            : '—',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un versement'),
              onPressed: () {
                Navigator.pop(ctx);
                _addPayment(s);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
