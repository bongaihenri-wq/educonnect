// lib/presentation/pages/super_admin/role_management/widgets/create_role_dialog.dart
import 'package:flutter/material.dart';
import '/../../data/repositories/role_repository.dart';

class CreateRoleDialog extends StatefulWidget {
  final List<String> countries;
  final RoleRepository repository;
  final VoidCallback onSuccess;

  const CreateRoleDialog({
    super.key,
    required this.countries,
    required this.repository,
    required this.onSuccess,
  });

  @override
  State<CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<CreateRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _levelController = TextEditingController(text: '1');
  
  String? _selectedCountryCode;
  String? _selectedSchoolId;
  List<Map<String, dynamic>> _schoolsInCountry = [];
  bool _isLoadingSchools = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.add_circle, color: Color(0xFF6B4EFF)),
          const SizedBox(width: 12),
          const Text('Nouveau rôle'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite, // ✅ Empêche le débordement
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Code du rôle *',
                    hintText: 'ex: admin, principal, assistant',
                    prefixIcon: const Icon(Icons.code),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Code obligatoire';
                    if (value.contains(' ')) return 'Pas d\'espaces';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom du rôle *',
                    hintText: 'ex: Administrateur',
                    prefixIcon: const Icon(Icons.label),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Nom obligatoire';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _levelController,
                  decoration: InputDecoration(
                    labelText: 'Niveau hiérarchique *',
                    hintText: '1=Enseignant, 2=Assistant, 3=Principal, 4=Admin',
                    prefixIcon: const Icon(Icons.format_list_numbered),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Niveau obligatoire';
                    final level = int.tryParse(value);
                    if (level == null || level < 1 || level > 4) {
                      return 'Niveau entre 1 et 4';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // ✅ CORRECTION : Dropdown avec texte tronqué
                DropdownButtonFormField<String?>(
                  isExpanded: true, // ✅ IMPORTANT : Évite le débordement
                  decoration: InputDecoration(
                    labelText: 'Pays (optionnel)',
                    hintText: 'Global si non sélectionné',
                    prefixIcon: const Icon(Icons.public),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  value: _selectedCountryCode,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('🌍 Global (tous les pays)'),
                    ),
                    ...widget.countries.map((code) {
                      return DropdownMenuItem(
                        value: code,
                        child: Text(
                          _getCountryName(code),
                          overflow: TextOverflow.ellipsis, // ✅ Tronque si trop long
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) async {
                    setState(() {
                      _selectedCountryCode = value;
                      _selectedSchoolId = null;
                      _schoolsInCountry = [];
                      _isLoadingSchools = value != null;
                    });

                    if (value != null) {
                      final schools = await widget.repository.getSchoolsByCountry(value);
                      setState(() {
                        _schoolsInCountry = schools;
                        _isLoadingSchools = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedCountryCode != null) ...[
                  if (_isLoadingSchools)
                    const Center(child: CircularProgressIndicator())
                  else if (_schoolsInCountry.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Aucune école trouvée pour ce pays',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // ✅ CORRECTION : Dropdown école avec texte tronqué
                    DropdownButtonFormField<String?>(
                      isExpanded: true, // ✅ IMPORTANT
                      decoration: InputDecoration(
                        labelText: 'École (optionnel)',
                        hintText: 'Toutes les écoles du pays si non sélectionné',
                        prefixIcon: const Icon(Icons.school),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      value: _selectedSchoolId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Toutes les écoles'),
                        ),
                        ..._schoolsInCountry.map((school) {
                          return DropdownMenuItem(
                            value: school['id']?.toString(),
                            child: Text(
                              school['name']?.toString() ?? 'Sans nom',
                              overflow: TextOverflow.ellipsis, // ✅ Tronque si trop long
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSchoolId = value);
                      },
                    ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6B4EFF).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Color(0xFF6B4EFF), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Si pays et école non sélectionnés, le rôle sera global.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B4EFF)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: Text(_isSubmitting ? 'Création...' : 'Créer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B4EFF),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim().toLowerCase();
    final name = _nameController.text.trim();
    final level = int.parse(_levelController.text.trim());

    if (['super_admin', 'parent', 'student'].contains(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Ce code est réservé'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await widget.repository.createRole(
      code: code,
      name: name,
      level: level,
      countryCode: _selectedCountryCode,
      schoolId: _selectedSchoolId,
    );

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${result['message']}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getCountryName(String code) {
    switch (code) {
      case '+225': return '🇨🇮 Côte d\'Ivoire';
      case '+237': return '🇨🇲 Cameroun';
      case '+221': return '🇸🇳 Sénégal';
      case '+233': return '🇬🇭 Ghana';
      case '+226': return '🇧🇫 Burkina Faso';
      case '+241': return '🇬🇦 Gabon';
      default: return code;
    }
  }
}