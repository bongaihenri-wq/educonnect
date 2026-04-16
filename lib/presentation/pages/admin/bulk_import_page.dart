import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/bulk_import_service.dart'; // Vérifie ce chemin

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
  List<Map<String, dynamic>>? _errors;
  ImportResult? _lastResult;

  Future<void> _import(String type, String title, String description) async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
      _errors = null;
    });

    try {
      final result = await BulkImportService.importFromCsv(
        type: type,
        schoolId: widget.schoolId,
        schoolCode: widget.schoolCode,
        schoolYear: widget.schoolYear,
      );

      setState(() {
        _isLoading = false;
        _lastResult = result;
        
        if (result.cancelled) {
          _resultMessage = 'Import annulé';
        } else if (result.success && !result.hasErrors) {
          _resultMessage = '✅ Import réussi !\n${result.created} créé(s), ${result.updated} mis à jour';
        } else {
          _resultMessage = '⚠️ Import partiel\n${result.created} créé(s), ${result.errors.length} erreur(s)';
          _errors = result.errors;
        }
      });

      if (!result.cancelled && mounted) {
        _showResultDialog(result);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultMessage = '❌ Erreur: $e';
      });
    }
  }

  void _showResultDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.success && !result.hasErrors ? 'Import réussi' : 'Import partiel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Créés : ${result.created}'),
              Text('Mis à jour : ${result.updated}'),
              Text('Supprimés : ${result.deleted}'),
              if (result.requestId != null) Text('Request ID : ${result.requestId}'),
              if (result.hasErrors) ...[
                const SizedBox(height: 16),
                const Text('Erreurs :', style: TextStyle(fontWeight: FontWeight.bold)),
                ...result.errors.take(5).map((e) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• Ligne ${e['row']}: ${e['error']}', 
                    style: const TextStyle(color: Colors.red, fontSize: 12)
                  ),
                )),
                if (result.errors.length > 5)
                  Text('... et ${result.errors.length - 5} autres erreurs'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import en masse'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.violet, Color(0xFF5B21B6)], // violetDark
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Import de données',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sélectionnez un fichier CSV pour importer vos données. Les doublons seront remplacés.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Import Élèves/Parents
                _buildImportCard(
                  icon: Icons.people,
                  color: Color(0xFF14B8A6), // teal
                  title: 'Élèves & Parents',
                  subtitle: 'CSV : niveau, classe, élève, parent, téléphone, matricule',
                  onTap: () => _import('students_parents', 'Élèves & Parents', 
                    'Importe les élèves et leurs parents. Crée automatiquement niveaux et classes.'),
                ),

                // Import Enseignants
                _buildImportCard(
                  icon: Icons.school,
                  color: AppTheme.violet,
                  title: 'Enseignants',
                  subtitle: 'CSV : matière, prénom, nom, téléphone, email, mot de passe',
                  onTap: () => _import('teachers', 'Enseignants',
                    'Importe les enseignants. Met à jour si l\'email existe déjà.'),
                ),

                // Import Emploi du Temps
                _buildImportCard(
                  icon: Icons.schedule,
                  color: Color(0xFFF59E0B), // sunshine/orange
                  title: 'Emploi du temps',
                  subtitle: 'CSV : classe, jour, début, fin, matière, email enseignant, salle',
                  onTap: () => _import('schedules', 'Emploi du temps',
                    'Importe les cours. Remplace les créneaux existants même jour/heure.'),
                ),

                if (_resultMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _lastResult?.success == true && !(_lastResult?.hasErrors ?? false)
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _lastResult?.success == true && !(_lastResult?.hasErrors ?? false)
                            ? Colors.green 
                            : Colors.orange,
                      ),
                    ),
                    child: Text(
                      _resultMessage!,
                      style: TextStyle(
                        color: _lastResult?.success == true && !(_lastResult?.hasErrors ?? false)
                            ? Colors.green.shade700 
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
