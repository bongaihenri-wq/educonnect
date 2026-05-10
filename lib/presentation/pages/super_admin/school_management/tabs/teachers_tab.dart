import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../config/theme.dart';
import '../dialogs/teacher_form_dialog.dart';

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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: AppTheme.violet),
              const SizedBox(width: 8),
              Text(
                'Enseignants (${widget.teachers.length})',
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
          child: widget.teachers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.teachers.length,
                  itemBuilder: (context, index) => _buildTeacherCard(widget.teachers[index]),
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
          Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucun enseignant', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.person_outline, color: Colors.white, size: 20),
        ),
        title: Text('${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tél: ${teacher['phone'] ?? 'Non renseigné'}'),
            if (teacher['specialization'] != null)
              Text('Spécialisation: ${teacher['specialization']}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        isThreeLine: teacher['specialization'] != null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _showEditDialog(teacher);
            if (value == 'delete') _confirmDelete(teacher);
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
      builder: (context) => TeacherFormDialog(schoolId: widget.schoolId),
    ).then((result) {
      if (result == true) widget.onDataChanged();
    });
  }

  void _showEditDialog(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (context) => TeacherFormDialog(
        schoolId: widget.schoolId,
        teacherData: teacher,
      ),
    ).then((result) {
      if (result == true) widget.onDataChanged();
    });
  }

  void _confirmDelete(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer l\'enseignant "${teacher['first_name']} ${teacher['last_name']}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Supprimer d'abord teacher_profiles
                await Supabase.instance.client.from('teacher_profiles').delete().eq('user_id', teacher['id']);
                // Puis app_users
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