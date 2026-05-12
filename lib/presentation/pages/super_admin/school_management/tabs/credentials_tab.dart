// lib/presentation/pages/admin/tabs/credentials_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/../config/theme.dart';

class CredentialsTab extends StatefulWidget {
  final String schoolCode;
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> parents;
  final List<Map<String, dynamic>> students;

  const CredentialsTab({
    super.key,
    required this.schoolCode,
    required this.teachers,
    required this.parents,
    required this.students,
  });

  @override
  State<CredentialsTab> createState() => _CredentialsTabState();
}

class _CredentialsTabState extends State<CredentialsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterCredentials(List<Map<String, dynamic>> credentials) {
    if (_searchQuery.isEmpty) return credentials;
    return credentials.where((c) {
      final query = _searchQuery.toLowerCase();
      return (c['name']?.toString().toLowerCase().contains(query) ?? false) ||
          (c['phone']?.toString().toLowerCase().contains(query) ?? false) ||
          (c['type']?.toString().toLowerCase().contains(query) ?? false) ||
          (c['matricule']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<Map<String, dynamic>> get _credentials {
    final credentials = <Map<String, dynamic>>[];
    
    // Credentials des parents
    for (final parent in widget.parents) {
      final linkedStudents = parent['parent_students'] as List<dynamic>? ?? [];
      String? studentMatricule;
      
      if (linkedStudents.isNotEmpty) {
        final studentData = linkedStudents.first['students'] as Map<String, dynamic>?;
        if (studentData != null) {
          studentMatricule = studentData['matricule']?.toString();
        }
      }
      
      if (studentMatricule == null && linkedStudents.isNotEmpty) {
        final studentId = linkedStudents.first['student_id']?.toString();
        final matchedStudent = widget.students.firstWhere(
          (s) => s['id'].toString() == studentId,
          orElse: () => {},
        );
        studentMatricule = matchedStudent['matricule']?.toString();
      }
      
      final matricule = studentMatricule ?? 'DEFAULT';
      
      // ⭐ MDP COURT = MATRICULE
      credentials.add({
        'type': 'parent',
        'name': '${parent['first_name'] ?? ''} ${parent['last_name'] ?? ''}',
        'phone': parent['phone'] ?? '',
        'password': matricule, // ⭐ COURT !
        'matricule': matricule,
      });
    }
    
    // Credentials des enseignants
    for (final teacher in widget.teachers) {
      final firstName = teacher['first_name'] ?? '';
      final lastName = teacher['last_name'] ?? '';
      final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A';
      
      // ⭐ MDP COURT = INITALE + NOM
      final password = '${initial}${lastName.toUpperCase()}';
      
      credentials.add({
        'type': 'teacher',
        'name': '$firstName $lastName',
        'phone': teacher['phone'] ?? '',
        'password': password, // ⭐ COURT !
      });
    }
    
    return credentials;
  }

  @override
  Widget build(BuildContext context) {
    final credentials = _credentials;
    final filteredCredentials = _filterCredentials(credentials);
    
    if (credentials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun credential disponible',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(credentials.length),
        // 🔍 BARRE DE RECHERCHE
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, téléphone, rôle...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: filteredCredentials.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun résultat pour "$_searchQuery"',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCredentials.length,
                  itemBuilder: (context, index) => _buildCredentialCard(context, filteredCredentials[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(int count) {
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
              'École: ${widget.schoolCode}',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '$count comptes',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialCard(BuildContext context, Map<String, dynamic> cred) {
    final type = cred['type']?.toString() ?? 'user';
    final name = cred['name']?.toString() ?? 'Inconnu';
    final phone = cred['phone']?.toString() ?? '';
    final password = cred['password']?.toString() ?? '';
    final matricule = cred['matricule']?.toString();

    final typeColor = type == 'parent' ? Colors.blue : Colors.orange;
    final typeIcon = type == 'parent' ? Icons.family_restroom : Icons.school;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        type == 'parent' ? 'Parent' : 'Enseignant',
                        style: TextStyle(fontSize: 12, color: typeColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone, 'Téléphone (Login)', phone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.key, 'Mot de passe', password, isPassword: true),
            if (matricule != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.numbers, 'Matricule enfant', matricule),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: 'Login: $phone\nMot de passe: $password',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copié !')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copier'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.violet,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareViaWhatsApp(context, name, phone, password),
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isPassword = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isPassword ? FontWeight.bold : FontWeight.normal,
              fontFamily: isPassword ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  void _shareViaWhatsApp(BuildContext context, String name, String phone, String password) {
    final message = 
      'Bonjour $name,\n\n'
      'Votre compte EduConnect est créé :\n'
      '• Téléphone (Login): $phone\n'
      '• Mot de passe: $password\n\n'
      'Téléchargez l\'application EduConnect.';

    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copié. Ouvrez WhatsApp et collez.'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}