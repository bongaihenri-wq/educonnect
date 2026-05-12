// lib/presentation/pages/super_admin/school_management/school_form_dialog.dart
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchoolFormDialog extends StatefulWidget {
  final Map<String, dynamic>? school;

  const SchoolFormDialog({super.key, this.school});

  @override
  State<SchoolFormDialog> createState() => _SchoolFormDialogState();
}

class _SchoolFormDialogState extends State<SchoolFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _codeController;
  late final TextEditingController _monthlyFeeController;

  String _planType = 'basic';
  String _countryCode = 'CI';
  bool _isActive = true;
  bool _isLoading = false;

  final List<Map<String, String>> _countries = [
    {'code': 'CI', 'name': 'Côte d\'Ivoire'},
    {'code': 'SN', 'name': 'Sénégal'},
    {'code': 'CM', 'name': 'Cameroun'},
    {'code': 'BJ', 'name': 'Bénin'},
    {'code': 'TG', 'name': 'Togo'},
    {'code': 'BF', 'name': 'Burkina Faso'},
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.school;
    _nameController = TextEditingController(text: s?['name'] ?? '');
    _addressController = TextEditingController(text: s?['address'] ?? '');
    _phoneController = TextEditingController(text: s?['phone'] ?? '');
    _emailController = TextEditingController(text: s?['email'] ?? '');
    _codeController = TextEditingController(text: s?['school_code'] ?? '');
    _monthlyFeeController = TextEditingController(text: (s?['monthly_fee'] ?? 5000).toString());
    if (s != null) {
      _planType = s['plan_type'] ?? 'basic';
      _countryCode = s['country_code'] ?? 'CI';
      _isActive = s['is_active'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  // 🔥 GÉNÉRATEUR D'API KEY
  String _generateApiKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hash = sha256.convert(bytes);
    return 'sk_live_${hash.toString().substring(0, 32)}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.school != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'école' : 'Nouvelle école'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'école *',
                  prefixIcon: Icon(Icons.school),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code école (unique) *',
                  prefixIcon: Icon(Icons.code),
                  hintText: 'Ex: COL2024, EDC2026',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Code école obligatoire';
                  if (v!.length < 4) return 'Minimum 4 caractères';
                  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(v.toUpperCase())) {
                    return 'Lettres et chiffres uniquement';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _planType,
                decoration: const InputDecoration(
                  labelText: 'Forfait',
                  prefixIcon: Icon(Icons.card_membership),
                ),
                items: ['free', 'basic', 'premium', 'enterprise']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _planType = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _monthlyFeeController,
                decoration: const InputDecoration(
                  labelText: 'Frais mensuel (XOF)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _countryCode,
                decoration: const InputDecoration(
                  labelText: 'Pays',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: _countries
                    .map((c) => DropdownMenuItem(value: c['code'], child: Text(c['name']!)))
                    .toList(),
                onChanged: (v) => setState(() => _countryCode = v!),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('École active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
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
          onPressed: _isLoading ? null : _saveSchool,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEditing ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }

  Future<void> _saveSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final schoolCode = _codeController.text.trim().toUpperCase();
      
      // Vérifie unicité du code
      final existing = await Supabase.instance.client
          .from('schools')
          .select('id, school_code')
          .eq('school_code', schoolCode)
          .maybeSingle();
      
      if (existing != null && (widget.school == null || existing['id'] != widget.school!['id'])) {
        throw Exception('Ce code école "$schoolCode" existe déjà.');
      }

      final data = {
        'name': _nameController.text.trim(),
        'school_code': schoolCode,
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'plan_type': _planType,
        'monthly_fee': int.tryParse(_monthlyFeeController.text) ?? 5000,
        'country_code': _countryCode,
        'is_active': _isActive,
        'currency': 'XOF',
        'settings': {},
      };

      if (widget.school != null) {
        // Update
        await Supabase.instance.client
            .from('schools')
            .update(data)
            .eq('id', widget.school!['id']);
      } else {
        // Insert avec nouvelle api_key
        data['api_key'] = _generateApiKey();
        
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          data['created_by'] = user.id;
        }
        
        await Supabase.instance.client.from('schools').insert(data);
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.school != null ? 'École modifiée' : 'École créée')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}