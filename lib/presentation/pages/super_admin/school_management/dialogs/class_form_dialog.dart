import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassFormDialog extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? classData;

  const ClassFormDialog({
    super.key,
    required this.schoolId,
    this.classData,
  });

  @override
  State<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _levelController;
  late final TextEditingController _capacityController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classData?['name'] ?? '');
    _levelController = TextEditingController(text: widget.classData?['level'] ?? '');
    _capacityController = TextEditingController(text: widget.classData?['capacity']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _levelController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.classData != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier la classe' : 'Nouvelle classe'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la classe *',
                  prefixIcon: Icon(Icons.class_),
                  hintText: 'Ex: 6ème A',
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _levelController,
                decoration: const InputDecoration(
                  labelText: 'Niveau',
                  prefixIcon: Icon(Icons.trending_up),
                  hintText: 'Ex: 6ème, 5ème, Terminale',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacité max',
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
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
        'name': _nameController.text.trim(),
        'level': _levelController.text.trim().isEmpty ? null : _levelController.text.trim(),
        'capacity': int.tryParse(_capacityController.text),
        'is_active': true,
      };

      if (widget.classData != null) {
        await Supabase.instance.client.from('classes').update(data).eq('id', widget.classData!['id']);
      } else {
        await Supabase.instance.client.from('classes').insert(data);
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