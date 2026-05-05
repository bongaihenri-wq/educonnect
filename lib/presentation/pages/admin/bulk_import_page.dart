import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/bulk_import_service.dart';

class BulkImportPage extends StatefulWidget {
  final String schoolId;
  final String schoolCode;
  final String schoolYear;

  const BulkImportPage({
    super.key,
    required this.schoolId,
    required this.schoolCode,
    this.schoolYear = '2024-2025',
  });

  @override
  State<BulkImportPage> createState() => _BulkImportPageState();
}

class _BulkImportPageState extends State<BulkImportPage> {
  bool _isLoading = false;
  String? _resultMessage;
  ImportResult? _lastResult;

  // CHANGEMENT : Utilisation de executeImport au lieu de importFromCsv
  Future<void> _import(String type, String title) async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      final result = await BulkImportService.executeImport(
        type: type,
        schoolId: widget.schoolId,
        schoolCode: widget.schoolCode,
        schoolYear: widget.schoolYear,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _lastResult = result;
        
        if (result.cancelled) {
          _resultMessage = 'Import annulé';
        } else if (result.success) {
          _resultMessage = result.hasErrors 
              ? '⚠️ Import partiel : ${result.created} créés, ${result.errorCount} erreurs'
              : '✅ Import réussi : ${result.created} créés, ${result.updated} mis à jour';
        } else {
          _resultMessage = '❌ Échec : ${result.message}';
        }
      });

      if (!result.cancelled) {
        _showResultDialog(title, result);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultMessage = '❌ Erreur fatale : $e';
      });
    }
  }

  void _showResultDialog(String title, ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result.success && !result.hasErrors ? Icons.check_circle : Icons.warning,
              color: result.success && !result.hasErrors ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Nouveaux enregistrements', result.created, Colors.green),
                _buildStatRow('Mises à jour', result.updated, Colors.blue),
                if (result.deleted > 0) _buildStatRow('Supprimés', result.deleted, Colors.red),
                
                if (result.hasErrors) ...[
                  const Divider(height: 32),
                  Text('Erreurs (${result.errorCount})', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 8),
                  ...result.errors.take(5).map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ligne ${e['row'] ?? '?'}: ${e['error'] ?? 'Erreur inconnue'}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  )),
                  if (result.errorCount > 5)
                    Center(child: Text('... et ${result.errorCount - 5} autres erreurs', 
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic))),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: AppTheme.violet)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Importation Massive'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header modernisé
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.violet, Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.violet.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                    const SizedBox(height: 12),
                    const Text('Gestion des imports',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Formats acceptés : Excel (.xlsx) et CSV. \nId École : ${widget.schoolCode}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              _buildImportCard(
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF14B8A6),
                title: 'Élèves & Parents',
                subtitle: 'Colonnes: niveau, classe, eleve_nom, parent_telephone...',
                onTap: () => _import('students_parents', 'Élèves & Parents'),
              ),

              _buildImportCard(
                icon: Icons.assignment_ind_rounded,
                color: AppTheme.violet,
                title: 'Enseignants',
                subtitle: 'Colonnes: matiere, prenom, nom, email, telephone...',
                onTap: () => _import('teachers', 'Enseignants'),
              ),

              _buildImportCard(
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFFF59E0B),
                title: 'Emploi du temps',
                subtitle: 'Colonnes: classe, jour, heure_debut, matiere, email...',
                onTap: () => _import('schedules', 'Emploi du temps'),
              ),

              if (_resultMessage != null) ...[
                const SizedBox(height: 20),
                _buildStatusBanner(),
              ],
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: AppTheme.violet)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final isSuccess = _lastResult?.success == true && !(_lastResult?.hasErrors ?? false);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSuccess ? Colors.green : Colors.orange),
      ),
      child: Row(
        children: [
          Icon(isSuccess ? Icons.check_circle : Icons.info, 
               color: isSuccess ? Colors.green : Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_resultMessage!,
                style: TextStyle(color: isSuccess ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}