// lib/presentation/pages/admin/tabs/classes_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dialogs/class_form_dialog.dart';

class ClassesTab extends StatefulWidget {
  final String schoolId;
  final List<Map<String, dynamic>> classes;
  final VoidCallback onDataChanged;

  const ClassesTab({
    super.key,
    required this.schoolId,
    required this.classes,
    required this.onDataChanged,
  });

  @override
  State<ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<ClassesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterClasses(List<Map<String, dynamic>> classes) {
    if (_searchQuery.isEmpty) return classes;
    return classes.where((c) {
      final query = _searchQuery.toLowerCase();
      return (c['name']?.toString().toLowerCase().contains(query) ?? false) ||
          (c['level']?.toString().toLowerCase().contains(query) ?? false);
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
              hintText: 'Rechercher une classe...',
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
          child: widget.classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Aucune classe trouvée'
                            : 'Aucun résultat pour "$_searchQuery"',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filterClasses(widget.classes).length,
                  itemBuilder: (context, index) {
                    final classData = _filterClasses(widget.classes)[index];
                    return _buildClassCard(classData);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.class_, color: Colors.white, size: 20),
        ),
        title: Text(classData['name'] ?? 'Sans nom'),
        subtitle: Text('Niveau: ${classData['level'] ?? 'Non défini'} | Capacité: ${classData['capacity'] ?? 'N/A'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _showEditDialog(classData);
            if (value == 'delete') _confirmDelete(classData);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> classData) {
    showDialog(
      context: context,
      builder: (context) => ClassFormDialog(
        schoolId: widget.schoolId,
        classData: classData,
      ),
    ).then((result) {
      if (result == true) widget.onDataChanged();
    });
  }

  void _confirmDelete(Map<String, dynamic> classData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer la classe "${classData['name']}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.from('classes').delete().eq('id', classData['id']);
                widget.onDataChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Classe supprimée'), backgroundColor: Colors.green),
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
