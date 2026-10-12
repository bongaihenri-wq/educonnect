// lib/features/payments/widgets/relances_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/payment_repository.dart';
import '../utils/payment_formatters.dart';

class RelancesTab extends StatefulWidget {
  final String schoolId;
  final List<Map<String, dynamic>> lateStudents;
  final bool loading;

  const RelancesTab({
    super.key,
    required this.schoolId,
    required this.lateStudents,
    required this.loading,
  });

  @override
  State<RelancesTab> createState() => _RelancesTabState();
}

class _RelancesTabState extends State<RelancesTab> {
  final Set<String> _selectedStudents = {};
  final _relanceMessageController = TextEditingController();
  final _relanceAmountController = TextEditingController();
  bool _sendingRelances = false;
  String _relanceClassFilter = 'tous';
  String _relanceAmountFilter = 'tous';
  // Résumé des relances déjà envoyées (par parent)
  Map<String, Map<String, dynamic>> _relanceSummary = {};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void didUpdateWidget(RelancesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lateStudents != widget.lateStudents) _loadSummary();
  }

  @override
  void dispose() {
    _relanceMessageController.dispose();
    _relanceAmountController.dispose();
    super.dispose();
  }

  // ── Chargement du résumé des relances ──────────────────────

  Future<void> _loadSummary() async {
    final ids = widget.lateStudents
        .map((s) => s['parent_id'])
        .whereType<String>()
        .toSet()
        .toList();
    if (ids.isEmpty) {
      if (mounted) setState(() => _relanceSummary = {});
      return;
    }
    try {
      final repo = PaymentRepository(Supabase.instance.client);
      final summary = await repo.getRelanceSummary(widget.schoolId, ids);
      if (mounted) setState(() => _relanceSummary = summary);
    } catch (_) {/* silencieux */}
  }

  String _shortDate(dynamic raw) {
    if (raw == null) return '—';
    final s = raw.toString();
    if (s.length < 10) return s;
    return '${s.substring(8, 10)}/${s.substring(5, 7)}/${s.substring(0, 4)}';
  }

  // Panneau détail : historique des relances d'un parent
  Future<void> _showRelanceHistory(String parentName, String parentId) async {
    final repo = PaymentRepository(Supabase.instance.client);
    final items = await repo.getRelanceHistory(parentId);
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
            Text('Relances — $parentName',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Aucune relance envoyée à ce parent',
                    textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final m = items[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.campaign, size: 18),
                      title: Text(m['title'] ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(m['content'] ?? '',
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Text(_shortDate(m['created_at']),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Filtres ────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filtered => widget.lateStudents.where((s) {
        if (_relanceClassFilter != 'tous' &&
            s['class_id'] != _relanceClassFilter) {
          return false;
        }
        if (_relanceAmountFilter != 'tous') {
          final amount = double.tryParse(_relanceAmountFilter);
          if (amount == null || (s['remaining'] as double) != amount) {
            return false;
          }
        }
        return true;
      }).toList();

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.lateStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 56, color: Colors.green.shade300),
            const SizedBox(height: 12),
            const Text('Aucun retardataire 🎉',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Tous les élèves importés sont à jour.',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final filtered = _filtered;
    final classOptions = <String, String>{
      'tous': 'Toutes les classes',
      for (final s in widget.lateStudents)
        s['class_id'] as String: s['class_name'] as String? ?? 'Sans classe',
    };
    final amountOptions = <String>{
      'tous',
      ...widget.lateStudents
          .map((s) => (s['remaining'] as double).toStringAsFixed(0)),
    };

    return Column(
      children: [
        // ── FILTRES ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Classe',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  value: _relanceClassFilter,
                  items: classOptions.entries.map((e) {
                    return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value,
                            maxLines: 1, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (v) => setState(() {
                    _relanceClassFilter = v ?? 'tous';
                    _selectedStudents.clear();
                  }),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Montant restant dû',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  value: _relanceAmountFilter,
                  items: amountOptions.map((a) {
                    return DropdownMenuItem(
                        value: a,
                        child: Text(a == 'tous'
                            ? 'Tous les montants'
                            : '${PaymentFormatters.fmt(double.parse(a))} F'));
                  }).toList(),
                  onChanged: (v) => setState(() {
                    _relanceAmountFilter = v ?? 'tous';
                    _selectedStudents.clear();
                  }),
                ),
              ),
            ],
          ),
        ),
        // ── SÉLECTION RAPIDE ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _selectedStudents
                    .addAll(filtered.map((s) => s['student_id'] as String))),
                child: const Text('Tout sélectionner',
                    style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedStudents.clear()),
                child: const Text('Tout désélectionner',
                    style: TextStyle(fontSize: 12)),
              ),
              const Spacer(),
              Text('${_selectedStudents.length}/${filtered.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        // ── LISTE + MESSAGE (structure anti-overflow) ──
        Expanded(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('Aucun résultat avec ces filtres'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final s = filtered[i];
                          final sid = s['student_id'] as String;
                          final isSelected = _selectedStudents.contains(sid);
                          final rel = _relanceSummary[s['parent_id']];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            elevation: 1,
                            color: isSelected ? Colors.orange.shade50 : null,
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selectedStudents.add(sid);
                                } else {
                                  _selectedStudents.remove(sid);
                                }
                              }),
                              title: Text(s['student_name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(children: [
                                    Text(
                                        '${s['matricule']} · Reste dû : ${PaymentFormatters.fmt(s['remaining'] as num)} F',
                                        style: const TextStyle(fontSize: 12)),
                                    Text(
                                        '  ·  ${s['class_name']}  ·  ${s['parent_name']}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600)),
                                  ]),
                                  // NOTE DISCRÈTE : relances déjà envoyées
                                  if (rel != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '📨 Relancé ${rel['count']}× — dernière : ${_shortDate(rel['lastAt'])}',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade600),
                                      ),
                                    ),
                                ],
                              ),
                              secondary: IconButton(
                                icon: Icon(Icons.history,
                                    size: 18, color: Colors.grey.shade500),
                                tooltip: 'Historique des relances',
                                onPressed: s['parent_id'] != null
                                    ? () => _showRelanceHistory(
                                        s['parent_name'] as String,
                                        s['parent_id'] as String)
                                    : null,
                              ),
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          );
                        },
                      ),
              ),
              // ── MESSAGE GROUPÉ (flexible, scroll interne) ──
              Flexible(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08), blurRadius: 8)
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _relanceAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Montant de la relance (F)',
                              hintText: 'Ex: 25 000',
                              prefixIcon: const Icon(Icons.payments, size: 18),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _relanceMessageController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText:
                                  'Message envoyé à tous les parents sélectionnés...',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('Modèle standard',
                                  style: TextStyle(fontSize: 12)),
                              onPressed: _prefillRelanceMessage,
                            ),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.orange.shade800),
                            icon: _sendingRelances
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send, size: 18),
                            label: Text(_sendingRelances
                                ? 'Envoi...'
                                : 'Relancer ${_selectedStudents.length} parent(s)'),
                            onPressed:
                                _selectedStudents.isEmpty || _sendingRelances
                                    ? null
                                    : _sendRelances,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Modèle de message ──────────────────────────────────────

  void _prefillRelanceMessage() {
    final amount = _relanceAmountController.text.trim();
    final amountTxt = amount.isEmpty
        ? '... F'
        : '${PaymentFormatters.fmt(double.tryParse(amount.replaceAll(' ', '')) ?? 0)} F';
    _relanceMessageController.text =
        'Cher(s) parent(s),\n\nNous vous rappelons qu\'un reste dû de $amountTxt est enregistré sur la scolarité de votre enfant.\n\nNous vous remercions de régulariser votre situation auprès de la comptabilité afin de garantir le suivi scolaire de votre enfant.\n\nCordialement,\nLa Comptabilité';
  }

  // ── Envoi groupé ───────────────────────────────────────────

  Future<void> _sendRelances() async {
    final message = _relanceMessageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez saisir un message'),
          backgroundColor: Colors.orange));
      return;
    }

    final targets = widget.lateStudents
        .where((s) =>
            _selectedStudents.contains(s['student_id']) &&
            s['parent_id'] != null)
        .toList();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aucun parent lié aux élèves sélectionnés'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _sendingRelances = true);
    final client = Supabase.instance.client;
    var sent = 0;
    try {
      for (final t in targets) {
        await client.from('admin_messages').insert({
          'school_id': widget.schoolId,
          'title': 'Rappel de paiement — Scolarité',
          'content': message,
          'recipient_type': 'specific_parent',
          'priority': 'high',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'sender_name': 'Comptabilité',
          'target_parent_id': t['parent_id'],
        });
        sent++;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Relance envoyée à $sent parent(s)'),
          backgroundColor: Colors.green));
      setState(() => _selectedStudents.clear());
      _loadSummary();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ Erreur : $e')));
    } finally {
      if (mounted) setState(() => _sendingRelances = false);
    }
  }
}
