import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/bulk_import_service.dart';
import '../../../services/csv_template_service.dart';
import '../../blocs/auth_bloc/auth_bloc.dart' as auth;
import '../super_admin/import_preview_page.dart';

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
  
  List<Map<String, dynamic>> _schools = [];
  String? _selectedSchoolId;
  String? _selectedSchoolCode;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _selectedSchoolId = widget.schoolId;
    _selectedSchoolCode = widget.schoolCode;
    _checkRoleAndLoadSchools();
  }

  Future<void> _checkRoleAndLoadSchools() async {
    final authState = context.read<auth.AuthBloc>().state;
    if (authState is auth.SuperAdminAuthenticated) {
      setState(() => _isSuperAdmin = true);
      try {
        final response = await Supabase.instance.client
            .from('schools')
            .select('id, name, school_code')
            .eq('is_active', true)
            .order('name');
        setState(() => _schools = List<Map<String, dynamic>>.from(response));
      } catch (e) {
        print('❌ Erreur chargement écoles: $e');
      }
    }
  }

  Future<void> _downloadTemplate(String type) async {
    try {
      final template = await CsvTemplateService.getTemplate(type);
      final description = CsvTemplateService.getTemplateDescription(type);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Template ${type.replaceAll('_', ' ')}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(description, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    template, 
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11)
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: template));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Template copié !')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copier'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickAndPreviewFile(String type) async {
    if (_selectedSchoolId == null || _selectedSchoolCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une école')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      // ⭐ NOUVEAU : Parse le fichier ici
      final parsedData = BulkImportService.parseFile(result);
      
      if (parsedData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le fichier ne contient aucune donnée valide'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      print('📄 Fichier: ${result.files.first.name}');
      print('📄 Lignes parsées: ${parsedData.length}');

      final previewResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImportPreviewPage(
            data: parsedData,           // ⭐ Passe les données parsées
            type: type,
            schoolId: _selectedSchoolId!,
            schoolCode: _selectedSchoolCode!, csvContent: '',
          ),
        ),
      );

      if (previewResult != null && previewResult['confirmed'] == true) {
        _proceedImport(type, parsedData);  // ⭐ Passe les données directement
      }
    } catch (e, stackTrace) {
      print('❌ Erreur pick file: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ⭐ CORRIGÉ : Accepte List<Map<String, dynamic>> au lieu de List<dynamic>
  Future<void> _proceedImport(String type, List<Map<String, dynamic>> data) async {
    setState(() => _isLoading = true);

    try {
      final result = await BulkImportService.executeImport(
        type: type,
        schoolId: _selectedSchoolId!,
        schoolCode: _selectedSchoolCode!,
        schoolYear: widget.schoolYear,
        data: data,  // ⭐ Passe les données parsées
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

      if (!result.cancelled && result.success) {
        Navigator.pushNamed(
          context, 
          '/import-report',
          arguments: {
            'result': result,
            'schoolId': _selectedSchoolId,
            'schoolCode': _selectedSchoolCode,
            'type': type,
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultMessage = '❌ Erreur fatale : $e';
      });
    }
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
              _buildHeader(),
              const SizedBox(height: 20),
              if (_isSuperAdmin) ...[
                _buildSchoolSelector(),
                const SizedBox(height: 20),
              ] else if (_selectedSchoolCode != null) ...[
                _buildCurrentSchoolCard(),
                const SizedBox(height: 20),
              ],
              _buildImportSection(
                type: 'students_parents',
                title: 'Élèves & Parents',
                color: const Color(0xFF14B8A6),
                icon: Icons.people_alt_rounded,
              ),
              _buildImportSection(
                type: 'teachers',
                title: 'Enseignants',
                color: AppTheme.violet,
                icon: Icons.assignment_ind_rounded,
              ),
              _buildImportSection(
                type: 'schedules',
                title: 'Emploi du temps',
                color: const Color(0xFFF59E0B),
                icon: Icons.calendar_today_rounded,
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.violet, Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          const SizedBox(height: 12),
          const Text(
            'Importation de données',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isSuperAdmin 
                ? 'Mode Super Admin - Sélectionnez une école'
                : 'École: ${_selectedSchoolCode ?? 'Non définie'}',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSchoolCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.school, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'École sélectionnée',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _selectedSchoolCode!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolSelector() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.violet.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: AppTheme.violet),
                const SizedBox(width: 8),
                Text(
                  'Sélectionner une école',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.violet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSchoolId,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              hint: const Text('Choisir une école...'),
              items: _schools.map((school) => DropdownMenuItem(
                value: school['id'] as String,
                child: Text('${school['name']} (${school['school_code'] ?? '---'})'),
              )).toList(),
              onChanged: (value) {
                final selected = _schools.firstWhere((s) => s['id'] == value);
                setState(() {
                  _selectedSchoolId = value;
                  _selectedSchoolCode = selected['school_code'] as String?;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection({
    required String type,
    required String title,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadTemplate(type),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Template'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickAndPreviewFile(type),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Importer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          Icon(
            isSuccess ? Icons.check_circle : Icons.info, 
            color: isSuccess ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _resultMessage!,
              style: TextStyle(
                color: isSuccess ? Colors.green.shade800 : Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}