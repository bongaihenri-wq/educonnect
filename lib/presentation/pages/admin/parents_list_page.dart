// lib/presentation/pages/admin/parents_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../blocs/auth_bloc/auth_bloc.dart' as auth;

class ParentsListPage extends StatefulWidget {
  const ParentsListPage({super.key});

  @override
  State<ParentsListPage> createState() => _ParentsListPageState();
}

class _ParentsListPageState extends State<ParentsListPage> {
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _filteredParents = [];
  bool _isLoading = true;
  String? _schoolId;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  Future<void> _loadParents() async {
    try {
      final state = context.read<auth.AuthBloc>().state;
      if (state is auth.Authenticated) {
        _schoolId = state.schoolId;
      }

      if (_schoolId == null) {
        setState(() {
          _isLoading = false;
          _error = 'School ID non trouvé';
        });
        return;
      }

      // Récupérer les parents avec leurs élèves
      final response = await Supabase.instance.client
          .from('parents')
          .select('''
            id,
            first_name,
            last_name,
            phone,
            email,
            address,
            subscription_status,
            subscription_end_date,
            students:students(
              id,
              first_name,
              last_name,
              matricule,
              classes(name)
            )
          ''')
          .eq('school_id', _schoolId!)
          .order('last_name');

      final parents = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        setState(() {
          _parents = parents;
          _filteredParents = parents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _filterParents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredParents = _parents;
      } else {
        _filteredParents = _parents.where((parent) {
          final fullName = '${parent['first_name']} ${parent['last_name']}'.toLowerCase();
          final phone = (parent['phone'] ?? '').toLowerCase();
          final email = (parent['email'] ?? '').toLowerCase();
          final search = query.toLowerCase();
          
          return fullName.contains(search) ||
                 phone.contains(search) ||
                 email.contains(search);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text('Parents'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadParents();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddParentDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterParents,
              decoration: InputDecoration(
                hintText: 'Rechercher un parent...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.bisDark),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          
          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text('Erreur: $_error'),
                            ElevatedButton(
                              onPressed: _loadParents,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _filteredParents.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.family_restroom, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Aucun parent trouvé',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredParents.length,
                            itemBuilder: (context, index) => _buildParentCard(_filteredParents[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentCard(Map<String, dynamic> parent) {
    final firstName = parent['first_name'] ?? 'Prénom';
    final lastName = parent['last_name'] ?? 'Nom';
    final phone = parent['phone'] ?? 'Téléphone non défini';
    final email = parent['email'] ?? 'Email non défini';
    final address = parent['address'] ?? 'Adresse non définie';
    final subscriptionStatus = parent['subscription_status'] ?? 'inactive';
    final subscriptionEndDate = parent['subscription_end_date'];
    
    final students = parent['students'] as List<dynamic>? ?? [];
    
    // Vérifier si l'abonnement est actif
    bool isActive = subscriptionStatus == 'active';
    if (subscriptionEndDate != null) {
      final endDate = DateTime.tryParse(subscriptionEndDate.toString());
      if (endDate != null && endDate.isBefore(DateTime.now())) {
        isActive = false;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.red,
          child: Icon(
            isActive ? Icons.check : Icons.warning,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          '$firstName $lastName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$phone • ${students.length} élève(s)',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isActive ? 'Actif' : 'Inactif',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                
                // Contact
                _buildInfoRow(Icons.phone, phone),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.email, email),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, address),
                
                const SizedBox(height: 16),
                
                // Élèves
                if (students.isNotEmpty) ...[
                  const Text(
                    'Élève(s) inscrit(s)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.nightBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...students.map((student) => _buildStudentChip(student)),
                  const SizedBox(height: 16),
                ],
                
                // Abonnement
                if (subscriptionEndDate != null) ...[
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Fin abonnement: ${_formatDate(subscriptionEndDate)}',
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showParentDetails(parent),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Détails'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _sendMessageToParent(parent),
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Message'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editParent(parent),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Modifier'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentChip(Map<String, dynamic> student) {
    final studentFirstName = student['first_name'] ?? '';
    final studentLastName = student['last_name'] ?? '';
    final matricule = student['matricule'] ?? 'N/A';
    final className = student['classes']?['name'] ?? 'Sans classe';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.violet.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.violet,
            radius: 16,
            child: Text(
              '${studentFirstName[0]}${studentLastName[0]}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$studentFirstName $studentLastName',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  'Matricule: $matricule • $className',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Non définie';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  void _showAddParentDialog() {
    // TODO: Implémenter l'ajout de parent
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout parent - à implémenter')),
    );
  }

  void _showParentDetails(Map<String, dynamic> parent) {
    // TODO: Navigation vers page détails parent
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Détails parent - à implémenter')),
    );
  }

  void _sendMessageToParent(Map<String, dynamic> parent) {
    final firstName = parent['first_name'] ?? '';
    final lastName = parent['last_name'] ?? '';
    
    // TODO: Implémenter la messagerie
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message à $firstName $lastName - à implémenter')),
    );
  }

  void _editParent(Map<String, dynamic> parent) {
    // TODO: Implémenter la modification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modification parent - à implémenter')),
    );
  }
}