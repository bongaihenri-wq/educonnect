// lib/presentation/pages/admin/admin_credentials_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme.dart';
import '../../../services/credentials_service.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../../services/pdf_export_service.dart';
import '../../../services/excel_export_service.dart';

class AdminCredentialsPage extends StatefulWidget {
  const AdminCredentialsPage({super.key});

  @override
  State<AdminCredentialsPage> createState() => _AdminCredentialsPageState();
}

class _AdminCredentialsPageState extends State<AdminCredentialsPage> {
  final CredentialsService _credentialsService = CredentialsService();
  List<UserCredential> _credentials = [];
  List<UserCredential> _filteredCredentials = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _schoolId;
  String? _schoolName;

  // Filtres
  String? _roleFilter; // 'all', 'parent', 'teacher'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCredentials();
    });
  }

  Future<void> _loadCredentials() async {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      _schoolId = state.schoolId;
      _schoolName = state.schoolName ?? 'Mon École';
    }

    if (_schoolId == null) {
      setState(() {
        _error = 'Impossible de déterminer l\'école';
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credentials =
          await _credentialsService.getSchoolCredentials(_schoolId!);
      if (mounted) {
        setState(() {
          _credentials = credentials;
          _filteredCredentials = credentials;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    var filtered = _credentials;

    // Filtre par rôle
    if (_roleFilter != null && _roleFilter != 'all') {
      filtered = filtered.where((c) => c.role == _roleFilter).toList();
    }

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.fullName.toLowerCase().contains(query) ||
            c.phone.contains(query) ||
            c.generatedPassword.toLowerCase().contains(query) ||
            (c.matricule?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() => _filteredCredentials = filtered);
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _applyFilters();
  }

  void _onRoleFilterChanged(String? role) {
    _roleFilter = role;
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        title: const Text('Identifiants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _loadCredentials,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header avec stats
          _buildHeader(),

          // Barre de recherche et filtres
          _buildSearchBar(),

          // Liste des credentials
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.violet))
                : _error != null
                    ? _buildError()
                    : _filteredCredentials.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final parentCount = _credentials.where((c) => c.role == 'parent').length;
    final teacherCount = _credentials.where((c) => c.role == 'teacher').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.violet, const Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _schoolName ?? 'École',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.family_restroom,
                    label: 'Parents',
                    count: parentCount,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.school,
                    label: 'Enseignants',
                    count: teacherCount,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Boutons d'export
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportToPDF,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.violet,
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.table_chart, size: 18),
                    label: const Text('Export Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.violet,
                      elevation: 0,
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, téléphone, matricule...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          // Filtres par rôle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleChip('Tous', 'all', Icons.people),
                const SizedBox(width: 8),
                _buildRoleChip('Parents', 'parent', Icons.family_restroom),
                const SizedBox(width: 8),
                _buildRoleChip('Enseignants', 'teacher', Icons.school),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, String role, IconData icon) {
    final isSelected =
        _roleFilter == role || (role == 'all' && _roleFilter == null);
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _onRoleFilterChanged(role == 'all' ? null : role),
      selectedColor: AppTheme.violet,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredCredentials.length,
      itemBuilder: (context, index) {
        final cred = _filteredCredentials[index];
        return _buildCredentialCard(cred);
      },
    );
  }

  Widget _buildCredentialCard(UserCredential cred) {
    final isParent = cred.role == 'parent';
    final typeColor = isParent ? Colors.blue : Colors.orange;
    final typeIcon = isParent ? Icons.family_restroom : Icons.school;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : nom + rôle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cred.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        cred.displayRole,
                        style: TextStyle(
                          fontSize: 12,
                          color: typeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouton copier
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copier les identifiants',
                  onPressed: () => _copyCredential(cred),
                ),
              ],
            ),
            const Divider(height: 20),
            // Téléphone
            _buildInfoRow(Icons.phone, 'Téléphone', cred.phone),
            const SizedBox(height: 8),
            // Mot de passe (mis en évidence)
            _buildPasswordRow(cred.generatedPassword),
            // Matricule (si parent)
            if (isParent && cred.matricule != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.confirmation_number, 'Matricule enfant',
                  cred.matricule!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRow(String password) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.key, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Text(
            'Mot de passe: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              password,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 18, color: Colors.amber.shade800),
            tooltip: 'Copier le mot de passe',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: password));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mot de passe copié !'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCredentials,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucun identifiant trouvé',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _copyCredential(UserCredential cred) {
    final text = '''
${cred.fullName} (${cred.displayRole})
Téléphone: ${cred.phone}
Mot de passe: ${cred.generatedPassword}
${cred.matricule != null ? 'Matricule enfant: ${cred.matricule}' : ''}
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Identifiants copiés !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _exportToPDF() async {
    if (_credentials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun identifiant à exporter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final filePath = await PdfExportService.exportCredentials(
        credentials: _filteredCredentials,
        schoolName: _schoolName ?? 'École',
        roleFilter: _roleFilter,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (filePath != null) {
          await PdfExportService.sharePdf(filePath);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF exporté avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'export PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    if (_credentials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun identifiant à exporter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final filePath = await ExcelExportService.exportCredentials(
        credentials: _filteredCredentials,
        schoolName: _schoolName ?? 'École',
        roleFilter: _roleFilter,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (filePath != null) {
          await ExcelExportService.shareExcel(filePath);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Excel exporté avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'export Excel'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
