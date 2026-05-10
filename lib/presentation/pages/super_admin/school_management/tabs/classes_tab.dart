import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../config/theme.dart';
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.class_, color: AppTheme.violet),
              const SizedBox(width: 8),
              Text(
                'Classes (${widget.classes.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.violet,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.classes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.classes.length,
                  itemBuilder: (context, index) => _buildClassCard(widget.classes[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucune classe', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
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

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => ClassFormDialog(schoolId: widget.schoolId),
    ).then((result) {
      if (result == true) widget.onDataChanged();
    });
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