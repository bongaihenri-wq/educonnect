import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../config/theme.dart';
import '../dialogs/student_form_dialog.dart';
import '../dialogs/parent_form_dialog.dart';

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
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Élèves'),
              Tab(text: 'Parents'),
            ],
            labelColor: AppTheme.violet,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.violet,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildStudentsTab(),
                _buildParentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.people, color: AppTheme.violet),
              const SizedBox(width: 8),
              Text(
                'Élèves (${widget.students.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddStudentDialog(),
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
          child: widget.students.isEmpty
              ? _buildEmptyState('élève', Icons.people)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.students.length,
                  itemBuilder: (context, index) => _buildStudentCard(widget.students[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildParentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.family_restroom, color: AppTheme.violet),
              const SizedBox(width: 8),
              Text(
                'Parents (${widget.parents.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddParentDialog(),
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
          child: widget.parents.isEmpty
              ? _buildEmptyState('parent', Icons.family_restroom)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.parents.length,
                  itemBuilder: (context, index) => _buildParentCard(widget.parents[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String label, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucun $label', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.person, color: Colors.white, size: 20),
        ),
        title: Text('${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'),
        subtitle: Text('Matricule: ${student['matricule'] ?? '---'} | Classe: ${student['classes']?['name'] ?? '---'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _showEditStudentDialog(student);
            if (value == 'delete') _confirmDeleteStudent(student);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _buildParentCard(Map<String, dynamic> parent) {
    final linkedStudents = parent['parent_students'] as List<dynamic>? ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.purple,
          child: Icon(Icons.family_restroom, color: Colors.white, size: 20),
        ),
        title: Text('${parent['first_name'] ?? ''} ${parent['last_name'] ?? ''}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tél: ${parent['phone'] ?? 'Non renseigné'}'),
            if (linkedStudents.isNotEmpty)
              Text('${linkedStudents.length} enfant(s)', style: const TextStyle(fontSize: 12)),
          ],
        ),
        isThreeLine: linkedStudents.isNotEmpty,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _showEditParentDialog(parent);
            if (value == 'delete') _confirmDeleteParent(parent);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => StudentFormDialog(schoolId: widget.schoolId),
    ).then((result) {
      if (result == true) widget.onDataChanged();
    });
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => StudentFormDialog(
        schoolId: widget.schoolId,
        studentData: student,
      ),
    ).then((result) {
      if (result == true) widget.onDataChanged();
    });
  }

  void _confirmDeleteStudent(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer l\'élève "${student['first_name']} ${student['last_name']}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Supprimer d'abord les liens parent_students
                await Supabase.instance.client.from('parent_students').delete().eq('student_id', student['id']);
                // Puis l'élève
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

  void _showAddParentDialog() {
    showDialog(
      context: context,
      builder: (context) => ParentFormDialog(schoolId: widget.schoolId),
    ).then((result) {
      if (result == true) widget.onDataChanged();
    });
  }

  void _showEditParentDialog(Map<String, dynamic> parent) {
    showDialog(
      context: context,
      builder: (context) => ParentFormDialog(
        schoolId: widget.schoolId,
        parentData: parent,
      ),
    ).then((result) {
      if (result == true) widget.onDataChanged();
    });
  }

  void _confirmDeleteParent(Map<String, dynamic> parent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer le parent "${parent['first_name']} ${parent['last_name']}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Supprimer d'abord les liens
                await Supabase.instance.client.from('parent_students').delete().eq('parent_id', parent['id']);
                // Puis parent_profiles
                await Supabase.instance.client.from('parent_profiles').delete().eq('user_id', parent['id']);
                // Puis app_users
                await Supabase.instance.client.from('app_users').delete().eq('id', parent['id']);
                widget.onDataChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Parent supprimé'), backgroundColor: Colors.green),
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