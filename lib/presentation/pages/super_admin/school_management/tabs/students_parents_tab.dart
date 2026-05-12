// lib/presentation/pages/admin/tabs/students_parents_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentsParentsTab extends StatefulWidget {
  final String schoolId;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> parents;
  final VoidCallback onDataChanged;

  const StudentsParentsTab({
    super.key,
    required this.schoolId,
    required this.students,
    required this.parents,
    required this.onDataChanged,
  });

  @override
  State<StudentsParentsTab> createState() => _StudentsParentsTabState();
}

class _StudentsParentsTabState extends State<StudentsParentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterStudents(List<Map<String, dynamic>> students) {
    if (_searchQuery.isEmpty) return students;
    return students.where((s) {
      final query = _searchQuery.toLowerCase();
      final fullName = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.toLowerCase();
      return fullName.contains(query) ||
          (s['matricule']?.toString().toLowerCase().contains(query) ?? false) ||
          (s['class_name']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔍 BARRE DE RECHERCHE
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, matricule, classe...',
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
          child: widget.students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Aucun élève trouvé'
                            : 'Aucun résultat pour "$_searchQuery"',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filterStudents(widget.students).length,
                  itemBuilder: (context, index) {
                    final student = _filterStudents(widget.students)[index];
                    return _buildStudentCard(student);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final fullName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}';
    final parent = widget.parents.firstWhere(
      (p) => p['id'] == student['parent_id'],
      orElse: () => {},
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange[100],
          child: Text(fullName.isNotEmpty ? fullName[0] : '?'),
        ),
        title: Text(fullName),
        subtitle: Text('Matricule: ${student['matricule'] ?? 'N/A'}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Classe', student['class_name'] ?? 'N/A'),
                _infoRow('Parent', '${parent['first_name'] ?? ''} ${parent['last_name'] ?? ''}'),
                _infoRow('Téléphone parent', parent['phone'] ?? 'N/A'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(student),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer ${student['first_name'] ?? ''} ${student['last_name'] ?? ''} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.from('students').delete().eq('id', student['id']);
                widget.onDataChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Élève supprimé'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}