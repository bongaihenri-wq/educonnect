import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherFormDialog extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? teacherData;

  const TeacherFormDialog({
    super.key,
    required this.schoolId,
    this.teacherData,
  });

  @override
  State<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _specializationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.teacherData?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: widget.teacherData?['last_name'] ?? '');
    _phoneController = TextEditingController(text: widget.teacherData?['phone'] ?? '');
    _specializationController = TextEditingController(text: widget.teacherData?['specialization'] ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.teacherData != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'enseignant' : 'Nouvel enseignant'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _specializationController,
                decoration: const InputDecoration(
                  labelText: 'Spécialisation/Matière',
                  prefixIcon: Icon(Icons.book),
                  hintText: 'Ex: Mathématiques, Français',
                ),
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

      if (widget.teacherData != null) {
        // Modification
        await supabase.from('app_users').update({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
        }).eq('id', widget.teacherData!['id']);

        // Mise à jour teacher_profiles
        await supabase.from('teacher_profiles').upsert({
          'user_id': widget.teacherData!['id'],
          'specialization': _specializationController.text.trim(),
        });
      } else {
        // Création
        final password = '${_firstNameController.text[0].toUpperCase()}${_lastNameController.text.toLowerCase()}@2024';
        
        // 1. Créer dans app_users
        final userResult = await supabase.from('app_users').insert({
          'school_id': widget.schoolId,
          'email': null,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'role': 'teacher',
          'phone': _phoneController.text.trim(),
          'is_active': true,
        }).select().single();

        // 2. Créer teacher_profiles
        await supabase.from('teacher_profiles').insert({
          'user_id': userResult['id'],
          'specialization': _specializationController.text.trim(),
          'qualifications': [],
        });
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