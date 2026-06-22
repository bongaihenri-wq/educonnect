// lib/presentation/pages/super_admin/role_management/widgets/create_user_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateUserDialog extends StatefulWidget {
  final String roleCode;
  final String roleName;
  final List<Map<String, dynamic>> schools;
  final String? defaultCountryCode;
  final bool isAdminSingleSchool;

  const CreateUserDialog({
    super.key,
    required this.roleCode,
    required this.roleName,
    required this.schools,
    this.defaultCountryCode,
    this.isAdminSingleSchool = false,
  });

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: '123456');

  // Champs dynamiques selon le rôle
  String? _selectedSchoolId;
  String? _selectedCountryCode;
  List<String> _selectedClassIds = [];
  List<Map<String, dynamic>> _classesInSchool = [];
  bool _isLoadingClasses = false;

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  bool get _isAssistant => widget.roleCode == 'assistant';
  bool get _isPrincipal => widget.roleCode == 'principal';

  final List<Map<String, String>> _countries = const [
    {'code': '+225', 'name': '🇨🇮 Côte d\'Ivoire'},
    {'code': '+237', 'name': '🇨🇲 Cameroun'},
    {'code': '+221', 'name': '🇸🇳 Sénégal'},
    {'code': '+233', 'name': '🇬🇭 Ghana'},
    {'code': '+226', 'name': '🇧🇫 Burkina Faso'},
    {'code': '+241', 'name': '🇬🇦 Gabon'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.defaultCountryCode != null) {
      _selectedCountryCode = '+${widget.defaultCountryCode}';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses(String schoolId) async {
    if (schoolId.isEmpty) return;
    setState(() => _isLoadingClasses = true);
    try {
      final result = await Supabase.instance.client
          .from('classes')
          .select('id, name, level')
          .eq('school_id', schoolId)
          .order('name');

      setState(() {
        _classesInSchool = List<Map<String, dynamic>>.from(result);
        _isLoadingClasses = false;
      });
    } catch (e) {
      setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation spécifique par rôle
    if (_isAssistant && (_selectedCountryCode == null || _selectedCountryCode!.isEmpty)) {
      setState(() => _errorMessage = 'Veuillez sélectionner un pays pour l\'assistant');
      return;
    }
    if (_isPrincipal && (_selectedSchoolId == null || _selectedSchoolId!.isEmpty)) {
      setState(() => _errorMessage = 'Veuillez sélectionner une école pour le principal');
      return;
    }
    if (_isPrincipal && _selectedClassIds.isEmpty) {
      setState(() => _errorMessage = 'Veuillez sélectionner au moins une classe');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      final response = await supabase.rpc(
        'create_user_with_role',
        params: {
          'p_first_name': _firstNameController.text.trim(),
          'p_last_name': _lastNameController.text.trim(),
          'p_phone': _phoneController.text.trim(),
          'p_email': _emailController.text.trim().isEmpty 
              ? null 
              : _emailController.text.trim(),
          'p_password': _passwordController.text,
          'p_role_code': widget.roleCode,
          'p_country_code': _isAssistant ? _selectedCountryCode : null,
          'p_school_id': _isPrincipal ? _selectedSchoolId : null,
          'p_created_by': currentUser?.id,
        },
      );

      if (response == null) {
        throw Exception('Réponse vide du serveur');
      }

      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        final newUserId = result['user_id'] as String?;

        // ✅ SI PRINCIPAL : Créer les liaisons classes
        if (_isPrincipal && newUserId != null && _selectedClassIds.isNotEmpty) {
          for (final classId in _selectedClassIds) {
            await supabase.from('principal_classes').insert({
              'principal_id': newUserId,
              'school_id': _selectedSchoolId,
              'class_id': classId,
            });
          }
        }

        setState(() {
          _successMessage = '✅ ${widget.roleName} créé !\n📱 ${result['phone']}\n🔑 MDP: ${result['password_temp']}';
        });
        
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur inconnue';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_add, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Créer ${widget.roleName}',
              style: const TextStyle(fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
            minWidth: 280,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Erreur
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Succès
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Prénom
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v?.trim().isEmpty == true ? 'Prénom obligatoire' : null,
                ),
                const SizedBox(height: 12),

                // Nom
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v?.trim().isEmpty == true ? 'Nom obligatoire' : null,
                ),
                const SizedBox(height: 12),

                // Téléphone
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone *',
                    hintText: _selectedCountryCode != null 
                        ? '$_selectedCountryCode 0701234567' 
                        : '+225 0701234567',
                    prefixIcon: const Icon(Icons.phone),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return 'Téléphone obligatoire';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optionnel)',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return null;
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v!.trim())) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ✅ ASSISTANT : Dropdown PAYS (obligatoire)
                if (_isAssistant) ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Pays *',
                      prefixIcon: Icon(Icons.public),
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCountryCode,
                    isExpanded: true,
                    items: _countries.map((c) {
                      return DropdownMenuItem(
                        value: c['code'],
                        child: Text(c['name']!, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCountryCode = v),
                    validator: (v) => v == null ? 'Pays obligatoire' : null,
                  ),
                  const SizedBox(height: 12),
                ],

                // ✅ PRINCIPAL : Dropdown ÉCOLE (obligatoire)
                if (_isPrincipal && widget.schools.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'École *',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSchoolId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sélectionner une école'),
                      ),
                      ...widget.schools.map((s) => DropdownMenuItem(
                        value: s['id']?.toString(),
                        child: Text(
                          '🏫 ${s['name']?.toString() ?? 'Sans nom'}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedSchoolId = v;
                        _selectedClassIds = [];
                        _classesInSchool = [];
                      });
                      if (v != null) _loadClasses(v);
                    },
                    validator: (v) => v == null ? 'École obligatoire' : null,
                  ),
                  const SizedBox(height: 12),

                  // ✅ PRINCIPAL : Sélection des CLASSES
                  if (_isLoadingClasses)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_selectedSchoolId != null && _classesInSchool.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(child: Text('Aucune classe dans cette école', style: TextStyle(color: Colors.orange))),
                        ],
                      ),
                    )
                  else if (_selectedSchoolId != null && _classesInSchool.isNotEmpty) ...[
                    Text(
                      'Classe(s) *',
                      style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _classesInSchool.map((cls) {
                        final classId = cls['id'] as String;
                        final isSelected = _selectedClassIds.contains(classId);
                        return FilterChip(
                          label: Text('${cls['name']} (${cls['level'] ?? ''})'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedClassIds.add(classId);
                              } else {
                                _selectedClassIds.remove(classId);
                              }
                            });
                          },
                          selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF6C63FF),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedClassIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Sélectionnez au moins une classe',
                          style: TextStyle(fontSize: 12, color: Colors.red[400]),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ],

                // École pour les autres rôles (non assistant, non principal)
                if (!_isAssistant && !_isPrincipal && widget.schools.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'École (optionnel)',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSchoolId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('🌍 Aucune école'),
                      ),
                      ...widget.schools.map((s) => DropdownMenuItem(
                        value: s['id']?.toString(),
                        child: Text(
                          '🏫 ${s['name']?.toString() ?? 'Sans nom'}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )),
                    ],
                    onChanged: (v) => setState(() => _selectedSchoolId = v),
                  ),

                const SizedBox(height: 12),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe temporaire',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    helperText: 'Par défaut: 123456 (modifiable)',
                    helperStyle: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                  ),
                  obscureText: true,
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Minimum 6 caractères' : null,
                ),

                const SizedBox(height: 16),

                // Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isAssistant
                              ? 'L\'assistant aura accès à TOUTES les écoles du pays sélectionné.'
                              : _isPrincipal
                                  ? 'Le principal verra les données des classes sélectionnées dans cette école.'
                                  : 'L\'utilisateur pourra se connecter avec son téléphone et ce mot de passe.',
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
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
        TextButton.icon(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          label: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting 
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_isSubmitting ? 'Création...' : 'Créer l\'utilisateur'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}