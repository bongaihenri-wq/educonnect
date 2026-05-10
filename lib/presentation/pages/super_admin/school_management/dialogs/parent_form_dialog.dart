import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParentFormDialog extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? parentData;

  const ParentFormDialog({
    super.key,
    required this.schoolId,
    this.parentData,
  });

  @override
  State<ParentFormDialog> createState() => _ParentFormDialogState();
}

class _ParentFormDialogState extends State<ParentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  List<String> _selectedStudentIds = [];
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  bool _isLoadingStudents = true;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.parentData?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: widget.parentData?['last_name'] ?? '');
    _phoneController = TextEditingController(text: widget.parentData?['phone'] ?? '');
    
    // Charger les élèves liés si modification
    if (widget.parentData != null) {
      final linkedStudents = widget.parentData!['parent_students'] as List<dynamic>? ?? [];
      _selectedStudentIds = linkedStudents
          .map((s) => s['student_id']?.toString())
          .whereType<String>()
          .toList();
    }
    
    _loadStudents();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final response = await Supabase.instance.client
          .from('students')
          .select('id, first_name, last_name, matricule')
          .eq('school_id', widget.schoolId)
          .eq('is_active', true)
          .order('last_name');
      
      setState(() {
        _students = List<Map<String, dynamic>>.from(response);
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() => _isLoadingStudents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.parentData != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier le parent' : 'Nouveau parent'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+22501020304',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Enfants rattachés',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _isLoadingStudents
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? const Text('Aucun élève disponible', style: TextStyle(color: Colors.grey))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _students.map((student) {
                            final studentId = student['id'].toString();
                            final isSelected = _selectedStudentIds.contains(studentId);
                            
                            return FilterChip(
                              label: Text('${student['first_name']} ${student['last_name']}'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedStudentIds.add(studentId);
                                  } else {
                                    _selectedStudentIds.remove(studentId);
                                  }
                                });
                              },
                              selectedColor: Colors.purple.withOpacity(0.2),
                              checkmarkColor: Colors.purple,
                            );
                          }).toList(),
                        ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEditing ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      if (widget.parentData != null) {
        // Modification
        await supabase.from('app_users').update({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
        }).eq('id', widget.parentData!['id']);

        // Supprimer anciens liens
        await supabase.from('parent_students').delete().eq('parent_id', widget.parentData!['id']);
        
        // Recréer les liens
        for (final studentId in _selectedStudentIds) {
          await supabase.from('parent_students').insert({
            'parent_id': widget.parentData!['id'],
            'student_id': studentId,
            'relationship': 'parent',
            'is_primary': true,
            'school_id': widget.schoolId,
          });
        }
      } else {
        // Création
        final password = 'DEFAULTEdu2024!'; // Mot de passe temporaire, à modifier
        
        final userResult = await supabase.from('app_users').insert({
          'school_id': widget.schoolId,
          'email': null,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'role': 'parent',
          'phone': _phoneController.text.trim(),
          'is_active': true,
        }).select().single();

        // Créer parent_profiles
        await supabase.from('parent_profiles').insert({
          'user_id': userResult['id'],
        });

        // Créer les liens avec les élèves
        for (final studentId in _selectedStudentIds) {
          await supabase.from('parent_students').insert({
            'parent_id': userResult['id'],
            'student_id': studentId,
            'relationship': 'parent',
            'is_primary': true,
            'school_id': widget.schoolId,
          });
        }
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}