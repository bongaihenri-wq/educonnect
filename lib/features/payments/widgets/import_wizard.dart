// lib/features/payments/widgets/import_wizard.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../logic/payments_bloc.dart';
import '../models/import_report.dart';

/// Assistant d'import en 4 étapes :
/// 1. Préparer → 2. Simuler → 3. Confirmer → 4. Vérifier
class ImportWizard extends StatefulWidget {
  final String schoolId;
  const ImportWizard({super.key, required this.schoolId});

  /// Ouvre l'assistant en plein écran, réutilise le PaymentsBloc du contexte
  static Future<void> open(BuildContext context, String schoolId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<PaymentsBloc>(),
        child: ImportWizard(schoolId: schoolId),
      ),
    );
  }

  @override
  State<ImportWizard> createState() => _ImportWizardState();
}

class _ImportWizardState extends State<ImportWizard> {
  // 0=Préparer, 1=Analyse, 2=Simuler(résultat), 3=Confirmer(envoi), 4=Vérifier
  int _step = 0;
  String? _pendingCsv;
  List<int>? _pendingBytes;
  bool _isExcel = false;
  ImportReport? _simReport;
  ImportReport? _finalReport;

  // ── Étapes ─────────────────────────────────────────────────

  static const _steps = [
    ('Préparer', Icons.folder_open),
    ('Simuler', Icons.fact_check),
    ('Confirmer', Icons.check_circle),
    ('Vérifier', Icons.verified),
  ];

  Widget _stepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: i <= _step
                        ? const Color(0xFF6C63FF)
                        : Colors.grey.shade300,
                    child: i < _step
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Icon(_steps[i].$2,
                            size: 14,
                            color: i == _step ? Colors.white : Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[i].$1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          i == _step ? FontWeight.bold : FontWeight.normal,
                      color: i <= _step ? const Color(0xFF6C63FF) : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (i < _steps.length - 1)
              Container(
                width: 16,
                height: 1,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.only(bottom: 16),
              ),
          ],
        ],
      ),
    );
  }

  // ── Sélection + simulation ─────────────────────────────────

  Future<void> _pickFile() async {
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
      _pendingBytes = file.bytes;
      _pendingCsv = null;
      _isExcel = true;
    } else {
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
      _pendingCsv = content;
      _pendingBytes = null;
      _isExcel = false;
    }

    setState(() {
      _step = 1;
      _simReport = null;
      _finalReport = null;
    });

    final bloc = context.read<PaymentsBloc>();
    if (_isExcel && _pendingBytes != null) {
      bloc.add(SimulateFileRequested(widget.schoolId, _pendingBytes!));
    } else if (_pendingCsv != null) {
      bloc.add(SimulateCsvRequested(widget.schoolId, _pendingCsv!));
    }
  }

  void _confirmImport() {
    setState(() => _step = 3);
    final bloc = context.read<PaymentsBloc>();
    if (_isExcel && _pendingBytes != null) {
      bloc.add(ImportFileRequested(widget.schoolId, _pendingBytes!));
    } else if (_pendingCsv != null) {
      bloc.add(ImportCsvRequested(widget.schoolId, _pendingCsv!));
    }
  }

  // ── Corps des étapes ───────────────────────────────────────

  Widget _buildPrepareStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Format attendu (ligne 1) :',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'matricule, periode, libelle, montant_du, montant_paye, date_paiement, date_echeance, montant_total',
              style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
              '• periode : AAAA-MM (mois de l\'échéance)\n'
              '• date_paiement : vide si non payé — un montant supérieur à la tranche est accepté (avance)\n'
              '• date_echeance : date limite de la tranche\n'
              '• montant_total : montant global de la scolarité (identique sur chaque ligne)\n'
              '• Excel (.xlsx) et CSV acceptés — l\'échéancier complet de l\'année est recommandé',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF)),
            icon: const Icon(Icons.upload_file),
            label: const Text('Choisir un fichier (Excel ou CSV)'),
            onPressed: _pickFile,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingStep() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Analyse du fichier en cours...\nAucune donnée n\'est écrite.',
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSimulateStep() {
    final report = _simReport!;
    final aborted = report.errorsJson
        .any((e) => (e['reason'] as String).contains('ANNULÉ'));

    if (aborted) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.cancel, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(report.errorsJson.first['reason'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700)),
            const Spacer(),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Choisir un autre fichier'),
              onPressed: () => setState(() => _step = 0),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              '${report.acceptedRows + report.rejectedRows} ligne(s) détectée(s)',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('✅ ${report.acceptedRows} ligne(s) valide(s)',
              style: const TextStyle(color: Colors.green)),
          Text('❌ ${report.rejectedRows} ligne(s) rejetée(s)',
              style: TextStyle(
                  color: report.rejectedRows > 0 ? Colors.red : Colors.grey)),
          if (report.errorsJson.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Détail des rejets :',
                style: TextStyle(fontWeight: FontWeight.w600)),
            ...report.errorsJson.take(6).map((e) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Ligne ${e['row']} (${e['matricule']}) : ${e['reason']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                )),
            if (report.errorsJson.length > 6)
              Text('... et ${report.errorsJson.length - 6} autre(s)',
                  style: const TextStyle(fontSize: 11)),
          ],
          const SizedBox(height: 8),
          const Text(
            'Aucune donnée n\'a encore été enregistrée.',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('Corriger le fichier'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF)),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmer l\'import'),
                  onPressed: report.acceptedRows > 0 ? _confirmImport : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmingStep() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Import en cours...\nNe fermez pas cette fenêtre.',
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildVerifyStep() {
    final report = _finalReport!;
    final hasRejections = report.rejectedRows > 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle,
              size: 56, color: hasRejections ? Colors.orange : Colors.green),
          const SizedBox(height: 12),
          Text(
            hasRejections
                ? 'Import terminé avec des rejets'
                : 'Import terminé avec succès',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '✅ ${report.acceptedRows} ligne(s) enregistrée(s)'
            '${hasRejections ? '  ·  ❌ ${report.rejectedRows} rejetée(s)' : ''}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Les statuts ont été recalculés et les parents notifiés.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
          if (hasRejections && report.errorsJson.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...report.errorsJson.take(5).map((e) => Text(
                  'Ligne ${e['row']} : ${e['reason']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.red),
                )),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: BlocListener<PaymentsBloc, PaymentsState>(
        listener: (context, state) {
          if (state is PaymentsSimulated && _step == 1) {
            setState(() {
              _simReport = state.report;
              _step = 2;
            });
          } else if (state is PaymentsImportDone && _step == 3) {
            setState(() {
              _finalReport = state.report;
              _step = 4;
            });
          } else if (state is PaymentsError && (_step == 1 || _step == 3)) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            setState(() => _step = 0);
          }
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Assistant d\'import',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              _stepIndicator(),
              const Divider(height: 1),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: switch (_step) {
                    0 => _buildPrepareStep(),
                    1 => _buildAnalyzingStep(),
                    2 => _buildSimulateStep(),
                    3 => _buildConfirmingStep(),
                    _ => _buildVerifyStep(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
