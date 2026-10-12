import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/payment_repository.dart';

class ParentPaymentsPage extends StatefulWidget {
  final String parentId;
  const ParentPaymentsPage({super.key, required this.parentId});

  @override
  State<ParentPaymentsPage> createState() => _ParentPaymentsPageState();
}

class _ParentPaymentsPageState extends State<ParentPaymentsPage> {
  final _repo = PaymentRepository(Supabase.instance.client);

  List<Map<String, dynamic>> _children = [];
  String? _selectedChildId;
  Map<String, dynamic>? _status;
  List<Map<String, dynamic>> _lines = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final children = await _repo.getMyChildren(widget.parentId);
      if (!mounted) return;
      setState(() {
        _children = children;
        if (children.isNotEmpty) {
          _selectedChildId = children.first['id'] as String;
        }
        _loading = false;
      });
      if (_selectedChildId != null) _loadChildData(_selectedChildId!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger vos enfants : $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadChildData(String studentId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await _repo.getMyChildStatus(studentId);
      final lines = await _repo.getMyChildLines(studentId);
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
            child: const Text('Annuler'),
          ),
          FilledButton(
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
      _loadChildData(_selectedChildId!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final upToDate = _status?['is_up_to_date'] as bool? ?? true;
    final remaining = ((_status?['amount_due'] as num?)?.toDouble() ?? 0) -
        ((_status?['amount_paid'] as num?)?.toDouble() ?? 0);
    final contested = _status?['contested'] as bool? ?? false;
    final updatedAt = _status?['updated_at'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comptabilité & Paiements'),
      ),
      body: _loading && _children.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _children.isEmpty
              ? Center(child: SelectableText(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sélecteur d'enfant (si plusieurs)
                      if (_children.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _children.map((c) {
                                final id = c['id'] as String;
                                final name =
                                    '${c['first_name']} ${c['last_name']}';
                                final selected = id == _selectedChildId;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    selected: selected,
                                    onSelected: (_) {
                                      setState(() => _selectedChildId = id);
                                      _loadChildData(id);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                      // Carte de situation
                      if (_status == null)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'Aucune donnée de paiement pour cet enfant.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else
                        Card(
                          color: upToDate
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      upToDate
                                          ? Icons.check_circle
                                          : Icons.warning_amber,
                                      color: upToDate
                                          ? Colors.green
                                          : Colors.orange.shade800,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        upToDate
                                            ? 'Situation à jour'
                                            : 'Reste dû : ${remaining.toStringAsFixed(0)} F',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (updatedAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Dernière mise à jour : ${updatedAt.substring(0, 10)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700),
                                  ),
                                ],
                                if (contested)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '⚠️ Contestation en cours de traitement',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade800),
                                    ),
                                  ),
                                if (!upToDate && !contested) ...[
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.flag_outlined,
                                        size: 18),
                                    label: const Text(
                                        'Je conteste cette situation'),
                                    onPressed: _contest,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Historique
                      if (_lines.isNotEmpty) ...[
                        Text('Historique des paiements',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _lines.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final l = _lines[i];
                              final paid =
                                  (l['amount_paid'] as num?)?.toDouble() ?? 0;
                              final due =
                                  (l['amount_due'] as num?)?.toDouble() ?? 0;
                              final complete = paid >= due;
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  complete
                                      ? Icons.check_circle_outline
                                      : Icons.schedule,
                                  color:
                                      complete ? Colors.green : Colors.orange,
                                  size: 22,
                                ),
                                title: Text(
                                  l['libelle'] ?? 'Période ${l['periode']}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  'Payé : ${paid.toStringAsFixed(0)} / ${due.toStringAsFixed(0)} F'
                                  '${l['paid_at'] != null ? '  ·  le ${(l['paid_at'] as String).substring(0, 10)}' : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  '${l['periode']}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
    );
  }
}
