// lib/presentation/pages/admin/tabs/teachers_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeachersTab extends StatefulWidget {
  final String schoolId;
  final List<Map<String, dynamic>> teachers;
  final VoidCallback onDataChanged;

  const TeachersTab({
    super.key,
    required this.schoolId,
    required this.teachers,
    required this.onDataChanged,
  });

  @override
  State<TeachersTab> createState() => _TeachersTabState();
}

class _TeachersTabState extends State<TeachersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterTeachers(List<Map<String, dynamic>> teachers) {
    if (_searchQuery.isEmpty) return teachers;
    return teachers.where((t) {
      final query = _searchQuery.toLowerCase();
      final fullName = '${t['first_name'] ?? ''} ${t['last_name'] ?? ''}'.toLowerCase();
      return fullName.contains(query) ||
          (t['email']?.toString().toLowerCase().contains(query) ?? false) ||
          (t['phone']?.toString().toLowerCase().contains(query) ?? false) ||
          (t['specialization']?.toString().toLowerCase().contains(query) ?? false);
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
              hintText: 'Rechercher un enseignant...',
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
          child: widget.teachers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Aucun enseignant trouvé'
                            : 'Aucun résultat pour "$_searchQuery"',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filterTeachers(widget.teachers).length,
                  itemBuilder: (context, index) {
                    final teacher = _filterTeachers(widget.teachers)[index];
                    return _buildTeacherCard(teacher);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    final fullName = '${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Text(fullName.isNotEmpty ? fullName[0] : '?'),
        ),
        title: Text(fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (teacher['email'] != null) Text(teacher['email']),
            if (teacher['phone'] != null) Text('📞 ${teacher['phone']}'),
            if (teacher['specialization'] != null) Text('📚 ${teacher['specialization']}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') _confirmDelete(teacher);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer ${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.from('app_users').delete().eq('id', teacher['id']);
                widget.onDataChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enseignant supprimé'), backgroundColor: Colors.green),
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