import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme.dart';
import '../../../services/bulk_import_service.dart';
import 'credentials_page.dart'; // ⭐ IMPORT AJOUTÉ

class ImportReportPage extends StatelessWidget {
  final ImportResult result;
  final String schoolId;
  final String schoolCode;
  final String type;

  const ImportReportPage({
    super.key,
    required this.result,
    required this.schoolId,
    required this.schoolCode,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final reportResult = args?['result'] as ImportResult? ?? result;
    final reportSchoolCode = args?['schoolCode'] as String? ?? schoolCode;
    final reportType = args?['type'] as String? ?? type;

    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Rapport d\'Importation'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReport(context, reportResult, reportSchoolCode),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(reportResult, reportSchoolCode, reportType),
            const SizedBox(height: 24),
            _buildSummary(reportResult),
            const SizedBox(height: 24),
            if (reportResult.errors.isNotEmpty) ...[
              _buildErrorsSection(reportResult),
              const SizedBox(height: 24),
            ],
            _buildSuccessInfo(reportResult),
            const SizedBox(height: 24),
            _buildCredentialsButton(context, reportResult, reportSchoolCode),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ImportResult result, String schoolCode, String type) {
    final isSuccess = result.success && !result.hasErrors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSuccess 
              ? [Colors.green, Colors.green.shade700]
              : [Colors.orange, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.warning,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSuccess ? 'Importation Réussie' : 'Importation Partielle',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'École: $schoolCode | Type: ${_getTypeLabel(type)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ImportResult result) {
    final total = result.total ?? (result.created + result.updated + result.errorCount);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résumé',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _SummaryCard(
              label: 'Créés',
              value: result.created.toString(),
              color: Colors.green,
              icon: Icons.add_circle,
            ),
            const SizedBox(width: 12),
            _SummaryCard(
              label: 'Mis à jour',
              value: result.updated.toString(),
              color: Colors.blue,
              icon: Icons.update,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _SummaryCard(
              label: 'Erreurs',
              value: result.errorCount.toString(),
              color: Colors.red,
              icon: Icons.error,
            ),
            const SizedBox(width: 12),
            _SummaryCard(
              label: 'Total',
              value: total.toString(),
              color: Colors.purple,
              icon: Icons.format_list_numbered,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorsSection(ImportResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Erreurs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 12),
        ...result.errors.take(10).map((error) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.red.withOpacity(0.05),
          child: ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.red),
            title: Text(
              'Ligne ${error['row'] ?? '?'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              error['error']?.toString() ?? 'Erreur inconnue',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        )),
        if (result.errors.length > 10)
          Center(
            child: Text(
              '... et ${result.errors.length - 10} autres erreurs',
              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessInfo(ImportResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comptes créés',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.green.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.green.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Importation complète',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.created} utilisateurs ont été créés avec leur mot de passe.\n'
                  'Connexion par numéro de téléphone.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ⭐ NOUVEAU : Bouton pour voir les credentials
  Widget _buildCredentialsButton(BuildContext context, ImportResult result, String schoolCode) {
    if (result.credentials.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CredentialsPage(
                credentials: result.credentials,
                schoolCode: schoolCode,
              ),
            ),
          );
        },
        icon: const Icon(Icons.people, color: Colors.white),
        label: Text(
          'Voir les ${result.credentials.length} comptes créés',
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.violet,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour au Dashboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.violet,
              side: BorderSide(color: AppTheme.violet),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _shareReport(BuildContext context, ImportResult result, String schoolCode) {
    final total = result.total ?? (result.created + result.updated + result.errorCount);
    
    final text = '''
RAPPORT IMPORTATION EDUCONNECT
École: $schoolCode
Type: ${_getTypeLabel(type)}
Date: ${DateTime.now()}

RÉSUMÉ:
- Créés: ${result.created}
- Mis à jour: ${result.updated}
- Erreurs: ${result.errorCount}
- Total: $total

${result.hasErrors ? 'ERREURS:\n${result.errors.map((e) => '- Ligne ${e['row']}: ${e['error']}').join('\n')}' : 'Aucune erreur'}
''';
    Share.share(text, subject: 'Rapport Import EduConnect $schoolCode');
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'students_parents': return 'Élèves & Parents';
      case 'teachers': return 'Enseignants';
      case 'schedules': return 'Emploi du temps';
      default: return type;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}