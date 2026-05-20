// lib/presentation/pages/super_admin/role_management/widgets/create_user_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateUserDialog extends StatefulWidget {
  final String roleCode;
  final String roleName;
  final List<Map<String, dynamic>> schools;
  final String? defaultCountryCode;

  const CreateUserDialog({
    super.key,
    required this.roleCode,
    required this.roleName,
    required this.schools,
    this.defaultCountryCode,
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

  String? _selectedSchoolId;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
          'p_country_code': widget.defaultCountryCode,
          'p_school_id': _selectedSchoolId,
          'p_created_by': currentUser?.id,
        },
      );

      if (response == null) {
        throw Exception('Réponse vide du serveur');
      }

      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        setState(() {
          _successMessage = '✅ Utilisateur créé !\n📱 ${result['phone']}\n🔑 MDP: ${result['password_temp']}';
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
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_add, color: theme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Créer ${widget.roleName}',
              style: const TextStyle(fontSize: 18),
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
                        Icon(Icons.check_circle, 
                             color: Colors.green.shade700, 
                             size: 20),
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
                  validator: (v) => v?.trim().isEmpty == true 
                      ? 'Prénom obligatoire' 
                      : null,
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
                  validator: (v) => v?.trim().isEmpty == true 
                      ? 'Nom obligatoire' 
                      : null,
                ),
                const SizedBox(height: 12),

                // Téléphone
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone *',
                    hintText: widget.defaultCountryCode != null 
                        ? '+${widget.defaultCountryCode}0701234567' 
                        : '+2250701234567',
                    prefixIcon: const Icon(Icons.phone),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  ],
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return 'Téléphone obligatoire';
                    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(v!.trim())) {
                      return 'Format invalide (ex: +2250701234567)';
                    }
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
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v!.trim())) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // École
                if (widget.schools.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'École (optionnel)',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSchoolId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('🌍 Aucune école'),
                      ),
                      ...widget.schools.map((s) => DropdownMenuItem(
                        value: s['id']?.toString(),
                        child: Text('🏫 ${s['name']?.toString() ?? 'Sans nom'}',
                        overflow: TextOverflow.ellipsis,
                        ),
                        
                      )),
                    ],
                    onChanged: (v) => setState(() => _selectedSchoolId = v),
                  ),

                const SizedBox(height: 12),

                // ⭐ CORRECTION : Mot de passe avec parenthèses autour de la condition
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe temporaire',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    helperText: 'Par défaut: 123456 (modifiable)',
                    helperStyle: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                  obscureText: true,
                  validator: (v) => (v?.length ?? 0) < 6   // ⭐ CORRIGÉ : parenthèses !
                      ? 'Minimum 6 caractères' 
                      : null,
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
                      Icon(Icons.info_outline, 
                           color: Colors.blue.shade700, 
                           size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'L\'utilisateur pourra se connecter avec son téléphone et ce mot de passe. Le rôle "${widget.roleName}" sera automatiquement attribué.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
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