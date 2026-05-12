import 'package:educonnect/presentation/pages/super_admin/school_management/dialogs/school_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../config/theme.dart';
import '/../../config/routes.dart';
import 'school_detail_page.dart';
import 'dialogs/school_form_dialog.dart';

class SchoolManagementPage extends StatefulWidget {
  const SchoolManagementPage({super.key});

  @override
  State<SchoolManagementPage> createState() => _SchoolManagementPageState();
}

class _SchoolManagementPageState extends State<SchoolManagementPage> {
  List<Map<String, dynamic>> _schools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      final response = await Supabase.instance.client
          .from('schools')
          .select('*, app_users!created_by(first_name, last_name)')
          .order('created_at', ascending: false);

      setState(() {
        _schools = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur chargement écoles: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text('Gestion des Écoles'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSchoolDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.violet))
          : _schools.isEmpty
              ? _buildEmptyState()
              : _buildSchoolsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune école enregistrée',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddSchoolDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une école'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.violet,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schools.length,
      itemBuilder: (context, index) {
        final school = _schools[index];
        return _SchoolCard(
          school: school,
          onEdit: () => _showEditSchoolDialog(school),
          onDelete: () => _confirmDelete(school),
          onViewDetails: () => _showSchoolDetails(school),
        );
      },
    );
  }

  void _showAddSchoolDialog() {
    showDialog(
      context: context,
      builder: (context) => const SchoolFormDialog(),
    ).then((_) => _loadSchools());
  }

  void _showEditSchoolDialog(Map<String, dynamic> school) {
    showDialog(
      context: context,
      builder: (context) => SchoolFormDialog(school: school),
    ).then((_) => _loadSchools());
  }

  void _confirmDelete(Map<String, dynamic> school) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer "${school['name']}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.from('schools').delete().eq('id', school['id']);
                _loadSchools();
                _showSuccess('École supprimée');
              } catch (e) {
                _showError('Erreur suppression: $e');
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSchoolDetails(Map<String, dynamic> school) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SchoolDetailPage(school: school),
      ),
    ).then((_) => _loadSchools());
  }
}

class _SchoolCard extends StatelessWidget {
  final Map<String, dynamic> school;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const _SchoolCard({
    required this.school,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = school['is_active'] ?? true;
    final planType = school['plan_type'] ?? 'basic';
    final createdBy = school['app_users'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isActive ? Colors.green : Colors.red,
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          school['name'] ?? 'Sans nom',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Code: ${school['school_code'] ?? '---'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                      if (value == 'import') _showImportMenu(context);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(
                        children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Modifier')],
                      )),
                      const PopupMenuItem(value: 'import', child: Row(
                        children: [Icon(Icons.upload_file, size: 18, color: Colors.green), SizedBox(width: 8), Text('Importer données', style: TextStyle(color: Colors.green))],
                      )),
                      const PopupMenuItem(value: 'delete', child: Row(
                        children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))],
                      )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Badge(label: planType.toUpperCase(), color: _getPlanColor(planType)),
                  const SizedBox(width: 8),
                  _Badge(label: isActive ? 'ACTIF' : 'INACTIF', color: isActive ? Colors.green : Colors.red),
                ],
              ),
              if (createdBy != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Créé par: ${createdBy['first_name'] ?? ''} ${createdBy['last_name'] ?? ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPlanColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'free': return Colors.grey;
      case 'basic': return Colors.blue;
      case 'premium': return Colors.purple;
      case 'enterprise': return Colors.orange;
      default: return Colors.blue;
    }
  }

  // ⭐ CORRIGÉ : Navigation vers BulkImportPage
  void _showImportMenu(BuildContext context) {
    final schoolId = school['id']?.toString() ?? '';
    final schoolCode = school['school_code']?.toString() ?? '';
    
    Navigator.pushNamed(
      context,
      AppRoutes.adminBulkImport,
      arguments: {
        'schoolId': schoolId,
        'schoolCode': schoolCode,
        'schoolYear': '2024-2025',
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}