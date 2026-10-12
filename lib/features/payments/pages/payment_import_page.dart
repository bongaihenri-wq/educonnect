import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/payment_repository.dart';
import '../logic/payments_bloc.dart';
import '../models/import_report.dart';
import '../models/payment_status_dto.dart';
import '../widgets/import_wizard.dart';

class _RowItem {
  final bool isHeader;
  final String? className;
  final int? count;
  final PaymentStatusDto? status;
  const _RowItem.header(this.className, this.count)
      : isHeader = true,
        status = null;
  const _RowItem.tile(this.status)
      : isHeader = false,
        className = null,
        count = null;
}

class PaymentImportPage extends StatefulWidget {
  final String schoolId;
  const PaymentImportPage({super.key, required this.schoolId});

  @override
  State<PaymentImportPage> createState() => _PaymentImportPageState();
}

class _PaymentImportPageState extends State<PaymentImportPage> {
  final _repo = PaymentRepository(Supabase.instance.client);
  final _searchController = TextEditingController();

  bool _gatingEnabled = false;
  String _filter = 'tous';
  String _search = '';
  Map<String, String> _classNames = {};
  ImportReport? _lastReport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentsBloc>().add(GradeGatingRequested(widget.schoolId));
      context
          .read<PaymentsBloc>()
          .add(PaymentsStatusRequested(widget.schoolId));
      _loadClassNames();
    });
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.toLowerCase());
    });
  }

  Future<void> _loadClassNames() async {
    try {
      final names = await _repo.getClassNames(widget.schoolId);
      if (mounted) setState(() => _classNames = names);
    } catch (_) {/* silencieux */}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Garde-fou UX ───────────────────────────────────────────

  Future<void> _onGatingChanged(bool newValue) async {
    if (newValue) {
      final lateCount = await _repo.countLateStudents(widget.schoolId);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Activer le blocage des notes ?'),
          content: Text(
            lateCount == 0
                ? 'Aucun élève n\'est actuellement en retard. Si des retards apparaissent après un import, les parents concernés ne verront plus le détail des notes.'
                : 'Attention : $lateCount élève(s) sont actuellement en retard de paiement. Leurs parents ne verront plus le détail des notes.',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Activer'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (!mounted) return;
    context
        .read<PaymentsBloc>()
        .add(GradeGatingToggled(widget.schoolId, newValue));
    setState(() => _gatingEnabled = newValue);
  }

  // ── Liste groupée + filtrée ────────────────────────────────

  List<PaymentStatusDto> _applyFilter(List<PaymentStatusDto> all) {
    var list = all;
    switch (_filter) {
      case 'ok':
        list = all.where((s) => s.isUpToDate && !s.contested).toList();
        break;
      case 'late':
        list = all.where((s) => !s.isUpToDate).toList();
        break;
      case 'contested':
        list = all.where((s) => s.contested).toList();
        break;
    }
    if (_search.isNotEmpty) {
      list = list
          .where((s) =>
              s.studentName.toLowerCase().contains(_search) ||
              s.matricule.toLowerCase().contains(_search))
          .toList();
    }
    return list;
  }

  List<_RowItem> _buildRows(List<PaymentStatusDto> statuses) {
    final filtered = _applyFilter(statuses);
    final groups = <String, List<PaymentStatusDto>>{};
    for (final s in filtered) {
      groups.putIfAbsent(s.classId.isEmpty ? '_' : s.classId, () => []).add(s);
    }
    final keys = groups.keys.toList()..sort();
    final items = <_RowItem>[];
    for (final k in keys) {
      final name = k == '_' ? 'Sans classe' : (_classNames[k] ?? 'Classe');
      items.add(_RowItem.header(name, groups[k]!.length));
      items.addAll(groups[k]!.map((s) => _RowItem.tile(s)));
    }
    return items;
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements & Verrouillage des notes')),
      body: Column(
        children: [
          // ══ TOGGLE ÉPINGLÉ : toujours visible, jamais caché ══
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              child: SwitchListTile(
                title: const Text(
                  'Conditionner l\'accès aux notes aux paiements',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Les parents non à jour ne voient pas le détail des notes',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12),
                ),
                value: _gatingEnabled,
                onChanged: _onGatingChanged,
              ),
            ),
          ),
          // ══ ZONE DÉFILANTE ══
          Expanded(
            child: BlocConsumer<PaymentsBloc, PaymentsState>(
              listener: (context, state) {
                if (state is GradeGatingLoaded) {
                  setState(() => _gatingEnabled = state.enabled);
                }
                if (state is PaymentsImportDone) {
                  setState(() => _lastReport = state.report);
                }
              },
              builder: (context, state) {
                if (state is PaymentsLoading && _lastReport == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PaymentsError && state is! PaymentsLoaded) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SelectableText(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                final statuses = state is PaymentsLoaded
                    ? state.statuses
                    : <PaymentStatusDto>[];
                final rows = _buildRows(statuses);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: 5 + rows.length,
                        itemBuilder: (context, index) {
                          if (index == 0) return _buildImportCard(context);
                          if (index == 1 && _lastReport != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _buildReportCard(_lastReport!),
                            );
                          }
                          if (index == 1 || index == 2) {
                            return const SizedBox.shrink();
                          }
                          if (index == 3) return _buildSearchBar();
                          if (index == 4) {
                            return _buildFilterChips(statuses.length);
                          }
                          final item = rows[index - 5];
                          if (item.isHeader) {
                            return _buildSectionHeader(
                                item.className!, item.count!);
                          }
                          return _buildStatusTile(context, item.status!);
                        },
                      ),
                    ),
                    // Indicateur de chargement (dans le bon scope)
                    if (state is PaymentsLoading)
                      const LinearProgressIndicator(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────

  Widget _buildImportCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text('Importer les paiements',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('Voir le modèle'),
                  onPressed: _showTemplateDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Fichier Excel ou CSV exporté depuis votre logiciel comptable.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Importer un fichier (Excel ou CSV)'),
              onPressed: () => ImportWizard.open(context, widget.schoolId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un nom ou un matricule...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _searchController.clear,
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildFilterChips(int total) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('tous', 'Tous ($total)'),
            const SizedBox(width: 8),
            _filterChip('ok', 'À jour'),
            const SizedBox(width: 8),
            _filterChip('late', 'En retard'),
            const SizedBox(width: 8),
            _filterChip('contested', 'Contestés'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final selected = _filter == key;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = key),
    );
  }

  Widget _buildSectionHeader(String className, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Icon(Icons.class_, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              className,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ImportReport report) {
    return Card(
      color: report.hasErrors ? Colors.orange.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import terminé : ${report.acceptedRows} acceptée(s), '
              '${report.rejectedRows} rejetée(s)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (report.hasErrors) ...[
              const SizedBox(height: 8),
              const Text('Lignes rejetées :',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              ...report.errorsJson.take(10).map((e) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Ligne ${e['row']} (${e['matricule']}) : ${e['reason']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  )),
              if (report.errorsJson.length > 10)
                Text('... et ${report.errorsJson.length - 10} autre(s)',
                    style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTile(BuildContext context, PaymentStatusDto s) {
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
        title: Text(
          s.studentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Wrap(
          children: [
            Text('${s.matricule} · Reste dû : ${_fmt(s.remaining)} F',
                style: const TextStyle(fontSize: 12)),
            if (s.contested)
              Text('  ·  ⚠️ Contesté',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            context.read<PaymentsBloc>().add(
                  ManualStatusSet(widget.schoolId, s.studentId, action == 'ok'),
                );
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'ok', child: Text('Marquer à jour')),
            PopupMenuItem(value: 'late', child: Text('Marquer non à jour')),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0);

  // ── Import ─────────────────────────────────────────────────

  Future<void> _pickAndImport(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final ext = (file.extension ?? '').toLowerCase();

    if (ext == 'xlsx') {
      if (file.bytes == null) return;
      context
          .read<PaymentsBloc>()
          .add(ImportFileRequested(widget.schoolId, file.bytes!));
      return;
    }

    String? content;
    if (file.bytes != null) {
      try {
        content = utf8.decode(file.bytes!, allowMalformed: false);
      } catch (_) {
        content = latin1.decode(file.bytes!, allowInvalid: true);
      }
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    }
    if (content == null || content.trim().isEmpty) return;
    if (!mounted) return;
    context
        .read<PaymentsBloc>()
        .add(ImportCsvRequested(widget.schoolId, content));
  }

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Format du fichier'),
        content: const SingleChildScrollView(
          child: Text(
            'En-tête (ligne 1) :\n'
            'matricule,periode,libelle,montant_du,montant_paye,date_paiement\n\n'
            'Exemple :\n'
            'ABC123,2026-09,Scolarité Tranche 1,75000,75000,2026-09-15\n'
            'ABC123,2026-10,Scolarité Tranche 2,75000,50000,\n\n'
            '• periode : AAAA-MM (mois de l\'échéance)\n'
            '• date_paiement : AAAA-MM-JJ ou JJ/MM/AAAA, vide si non payé\n'
            '• Réimporter le même mois met à jour, ne duplique pas',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
