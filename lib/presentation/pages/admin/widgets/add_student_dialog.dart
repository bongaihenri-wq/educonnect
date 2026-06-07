// lib/presentation/pages/admin/widgets/add_student_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme.dart';

class AddStudentDialog extends StatefulWidget {
  final String schoolId;
  final String schoolCode;
  final List<Map<String, dynamic>> classes;
  final Function(Map<String, dynamic> studentData) onSubmit;

  const AddStudentDialog({
    super.key,
    required this.schoolId,
    required this.schoolCode,
    required this.classes,
    required this.onSubmit,
  });

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();
  final _parentFirstNameCtrl = TextEditingController();
  final _parentLastNameCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  
  String? _selectedClassId;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _matriculeCtrl.dispose();
    _parentFirstNameCtrl.dispose();
    _parentLastNameCtrl.dispose();
    _parentPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.violet,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ajouter un élève',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Formulaire
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === INFORMATIONS ÉLÈVE ===
                      _buildSectionTitle('Informations Élève', Icons.school),
                      const SizedBox(height: 12),
                      
                      _buildTextField(
                        controller: _firstNameCtrl,
                        label: 'Prénom',
                        icon: Icons.person,
                        validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildTextField(
                        controller: _lastNameCtrl,
                        label: 'Nom',
                        icon: Icons.person_outline,
                        validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildTextField(
                        controller: _matriculeCtrl,
                        label: 'Matricule',
                        icon: Icons.badge,
                        validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      // Sélection classe
                      DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        decoration: InputDecoration(
                          labelText: 'Classe',
                          prefixIcon: const Icon(Icons.class_, color: AppTheme.violet),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: widget.classes.map((classe) {
                          return DropdownMenuItem<String>(
                            value: classe['id'] as String,
                            child: Text('${classe['level']} ${classe['name']}'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedClassId = value),
                        validator: (v) => v == null ? 'Sélectionnez une classe' : null,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // === INFORMATIONS PARENT ===
                      _buildSectionTitle('Informations Parent', Icons.family_restroom),
                      const SizedBox(height: 12),
                      
                      _buildTextField(
                        controller: _parentFirstNameCtrl,
                        label: 'Prénom du parent',
                        icon: Icons.person,
                        validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildTextField(
                        controller: _parentLastNameCtrl,
                        label: 'Nom du parent',
                        icon: Icons.person_outline,
                        validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildTextField(
                        controller: _parentPhoneCtrl,
                        label: 'Téléphone parent (+225...)',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Champ requis';
                          if (!v!.startsWith('+')) return 'Format: +225XXXXXXXX';
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Info connexion parent
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _parentPhoneCtrl,
                          _matriculeCtrl,
                        ]),
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Connexion parent',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Le parent se connectera avec:\n'
                                  '• Téléphone: ${_parentPhoneCtrl.text.isEmpty ? '+225...' : _parentPhoneCtrl.text}\n'
                                  '• Mot de passe: ${_matriculeCtrl.text.isEmpty ? 'Matricule' : _matriculeCtrl.text}\n'
                                  '• Code école: ${widget.schoolCode}',
                                  style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Boutons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.violet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Ajouter'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.violet, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.nightBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.violet),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.violet, width: 2),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final data = {
      'student': {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'matricule': _matriculeCtrl.text.trim(),
        'class_id': _selectedClassId,
        'school_id': widget.schoolId,
      },
      'parent': {
        'first_name': _parentFirstNameCtrl.text.trim(),
        'last_name': _parentLastNameCtrl.text.trim(),
        'phone': _parentPhoneCtrl.text.trim(),
        'school_id': widget.schoolId,
        'school_code': widget.schoolCode,
        'role': 'parent',
      },
    };
    
    widget.onSubmit(data);
  }
}