// lib/presentation/pages/parent/widgets/compta_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:educonnect/features/payments/data/payment_repository.dart';
import '../../../../config/theme.dart';

class ComptaTab extends StatefulWidget {
  final String studentId;
  const ComptaTab({super.key, required this.studentId});

  @override
  State<ComptaTab> createState() => _ComptaTabState();
}

class _ComptaTabState extends State<ComptaTab> {
  final _repo = PaymentRepository(Supabase.instance.client);

  Map<String, dynamic>? _status;
  List<Map<String, dynamic>> _lines = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await _repo.getMyChildStatus(widget.studentId);
      final lines = await _repo.getMyChildLines(widget.studentId);
      // L'alerte "mise à jour" se consomme au clic dans la page Alertes
      if (!mounted) return;
      setState(() {
        _status = status;
        _lines = lines;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Chargement impossible : $e';
        _loading = false;
      });
    }
  }

  Future<void> _contest() async {
    if (_status == null) return;
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contester ma situation'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Décrivez le problème (ex: paiement effectué le...)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.violet),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (message == null || message.isEmpty) return;
    try {
      await _repo.contestStatus(_status!['id'] as String, message);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Contestation envoyée à l\'établissement')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  // ── Formatage ──────────────────────────────────────────────

  String _fmt(num v) {
    final s = v.toStringAsFixed(0);
    return s.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return '—';
    final s = raw.toString();
    if (s.length < 10) return s;
    return '${s.substring(8, 10)}/${s.substring(5, 7)}/${s.substring(0, 4)}';
  }

  String get _currentPeriod {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ── Statut d'une ligne (échéancier complet) ────────────────

  /// paye | retard | partiel | avenir
  String _lineStatus(Map<String, dynamic> l) {
    final paid = (l['amount_paid'] as num?)?.toDouble() ?? 0;
    final due = (l['amount_due'] as num?)?.toDouble() ?? 0;
    if (due <= 0) return 'info';
    if (paid >= due) return 'paye';
    final periode = (l['periode'] as String?) ?? '';
    final periodeEchue = periode.compareTo(_currentPeriod) <= 0;
    final rawDate = l['due_date'];
    final dateEchue = rawDate != null &&
        DateTime.tryParse(rawDate.toString())?.isBefore(DateTime.now()) == true;
    if (periodeEchue || dateEchue) {
      return paid > 0 ? 'partiel' : 'retard';
    }
    return 'avenir';
  }

  Widget _statusBadge(String status) {
    final labels = <String, String>{
      'paye': 'Soldé',
      'retard': 'En retard',
      'partiel': 'Partiel',
      'avenir': 'À venir',
      'info': '—',
    };
    final colors = <String, Color>{
      'paye': Colors.green,
      'retard': Colors.red,
      'partiel': Colors.orange,
      'avenir': Colors.blueGrey,
      'info': Colors.grey,
    };
    final c = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(labels[status] ?? '—',
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.violet));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(_error!,
              style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_status == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucune donnée de scolarité disponible pour le moment.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final upToDate = _status!['is_up_to_date'] as bool? ?? true;
    final contested = _status!['contested'] as bool? ?? false;
    final updatedAt = _status!['updated_at'] as String?;

    // Base globale : montant_total du fichier prioritaire,
    // sinon somme des lignes importées
    final totalFee = (_status!['total_fee'] as num?)?.toDouble();
    final base =
        totalFee ?? ((_status!['amount_due'] as num?)?.toDouble() ?? 0);

    // Reste dû = base globale − total payé
    final remaining =
        base - ((_status!['amount_paid'] as num?)?.toDouble() ?? 0);

    // Solde progressif : calcul de l'ancien au récent
    final sorted = [..._lines]
      ..sort((a, b) => '${a['periode']}'.compareTo('${b['periode']}'));
    var cumDue = 0.0;
    var cumPaid = 0.0;
    final balances = <String, double>{};
    for (final l in sorted) {
      cumDue += (l['amount_due'] as num?)?.toDouble() ?? 0;
      cumPaid += (l['amount_paid'] as num?)?.toDouble() ?? 0;
      balances[l['id']?.toString() ?? '${l['periode']}${l['libelle']}'] =
          cumDue - cumPaid;
    }

    // Prochaine échéance impayée
    Map<String, dynamic>? nextDueLine;
    for (final l in sorted) {
      final paidL = (l['amount_paid'] as num?)?.toDouble() ?? 0;
      final dueL = (l['amount_due'] as num?)?.toDouble() ?? 0;
      if (dueL > 0 && paidL < dueL && l['due_date'] != null) {
        nextDueLine = l;
        break;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ══ EN-TÊTE : TOTAL À GAUCHE / RESTE DÛ À DROITE ══
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // GAUCHE : SCOLARITÉ TOTALE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scolarité totale',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              '${_fmt(base)} F',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 12),
                      // DROITE : RESTE DÛ
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Reste dû',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              '${_fmt(remaining)} F',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: remaining > 0
                                    ? Colors.orange.shade800
                                    : Colors.green.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Statut
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: upToDate
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          upToDate ? Icons.check_circle : Icons.warning_amber,
                          size: 16,
                          color: upToDate
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          upToDate ? 'Situation à jour' : 'Paiement en retard',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: upToDate
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (updatedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Dernière mise à jour : ${updatedAt.substring(0, 10)}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                  // PROCHAINE ÉCHÉANCE
                  if (nextDueLine != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '⏳ Prochaine échéance : ${_fmtDate(nextDueLine['due_date'])} (${nextDueLine['libelle'] ?? ''})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800),
                    ),
                  ],
                  if (contested)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '⚠️ Contestation en cours de traitement',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  if (!upToDate && !contested) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Je conteste cette situation'),
                      onPressed: _contest,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ══ ÉCHÉANCIER & PAIEMENTS ══
          if (_lines.isNotEmpty) ...[
            Text('Échéancier & paiements',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lines.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final l = _lines[i];
                  final paid = (l['amount_paid'] as num?)?.toDouble() ?? 0;
                  final due = (l['amount_due'] as num?)?.toDouble() ?? 0;
                  final status = _lineStatus(l);
                  final key =
                      l['id']?.toString() ?? '${l['periode']}${l['libelle']}';
                  final balance = balances[key] ?? 0;
                  final dueDate = l['due_date'];
                  final isFuture = status == 'avenir';

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status == 'paye'
                                  ? Icons.check_circle_outline
                                  : status == 'avenir'
                                      ? Icons.event
                                      : Icons.schedule,
                              color: status == 'paye'
                                  ? Colors.green
                                  : status == 'retard'
                                      ? Colors.red
                                      : status == 'partiel'
                                          ? Colors.orange
                                          : Colors.blueGrey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l['libelle'] ?? 'Période ${l['periode']}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                            _statusBadge(status),
                            const SizedBox(width: 6),
                            Text('${l['periode']}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text(
                                status == 'paye'
                                    ? 'Payé : ${_fmt(paid)} F  ·  le ${_fmtDate(l['paid_at'])}'
                                    : 'Payé : ${_fmt(paid)} / ${_fmt(due)} F'
                                        '${l['paid_at'] != null ? '  ·  le ${_fmtDate(l['paid_at'])}' : ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (dueDate != null)
                                Text(
                                  'Échéance : ${_fmtDate(dueDate)}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: status == 'retard'
                                          ? Colors.red.shade700
                                          : Colors.grey.shade700),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: isFuture
                              ? Text(
                                  'À échoir : ${_fmt(due)} F',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey.shade600),
                                )
                              : Text(
                                  'Reste dû après : ${_fmt(balance)} F',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: balance > 0
                                        ? Colors.orange.shade800
                                        : Colors.green.shade700,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
