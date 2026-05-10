import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentFormDialog extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? studentData;

  const StudentFormDialog({
    super.key,
    required this.schoolId,
    this.studentData,
  });

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _matriculeController;
  String? _selectedClassId;
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = false;
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.studentData?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: widget.studentData?['last_name'] ?? '');
    _matriculeController = TextEditingController(text: widget.studentData?['matricule'] ?? '');
    _selectedClassId = widget.studentData?['class_id']?.toString();
    _loadClasses();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final response = await Supabase.instance.client
          .from('classes')
          .select('id, name')
          .eq('school_id', widget.schoolId)
          .order('name');
      
      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
        _isLoadingClasses = false;
      });
    } catch (e) {
      setState(() => _isLoadingClasses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.studentData != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'élève' : 'Nouvel élève'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _matriculeController,
                decoration: const InputDecoration(
                  labelText: 'Matricule *',
                  prefixIcon: Icon(Icons.numbers),
                  hintText: 'Ex: MAT001',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
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
              _isLoadingClasses
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Classe',
                        prefixIcon: Icon(Icons.class_),
                      ),
                      hint: const Text('Sélectionner une classe'),
                      items: _classes.map((c) => DropdownMenuItem(
                        value: c['id'].toString(),
                        child: Text(c['name'] ?? 'Sans nom'),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedClassId = v),
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
      final data = {
        'school_id': widget.schoolId,
        'matricule': _matriculeController.text.trim().toUpperCase(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'class_id': _selectedClassId,
        'is_active': true,
      };

      if (widget.studentData != null) {
        await Supabase.instance.client.from('students').update(data).eq('id', widget.studentData!['id']);
      } else {
        await Supabase.instance.client.from('students').insert(data);
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