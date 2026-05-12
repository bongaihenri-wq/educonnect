// lib/presentation/pages/login/school_login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '/presentation/blocs/auth_bloc/auth_bloc.dart' as auth;

class SchoolLoginPage extends StatefulWidget {
  const SchoolLoginPage({super.key});

  @override
  State<SchoolLoginPage> createState() => _SchoolLoginPageState();
}

class _SchoolLoginPageState extends State<SchoolLoginPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _schoolCodeController = TextEditingController();

  bool _obscurePassword = true;
  String? _schoolName;
  bool _isValidatingSchool = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    _schoolCodeController.text = prefs.getString('saved_school_code') ?? '';
    _phoneController.text = prefs.getString('saved_phone') ?? '';
    
    if (_schoolCodeController.text.isNotEmpty) {
      _verifySchool(_schoolCodeController.text);
    }
  }

  Future<void> _verifySchool(String code) async {
    if (code.length < 3) return;
    setState(() => _isValidatingSchool = true);
    
    try {
      final school = await Supabase.instance.client
          .from('schools')
          .select('id, name')
          .ilike('school_code', code.trim())
          .eq('is_active', true)
          .maybeSingle();

      setState(() {
        _schoolName = school?['name'];
        _isValidatingSchool = false;
      });
    } catch (e) {
      setState(() => _isValidatingSchool = false);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // ⭐ COMME AVANT : L'utilisateur tape le numéro complet avec +225
    final phone = _phoneController.text.replaceAll(RegExp(r'\s'), '');
      print('🔍 TELEPHONE ENVOYE: "$phone"');
  print('🔍 LONGUEUR: ${phone.length}');
  print('🔍 CODEPOINTS: ${phone.runes.toList()}');

    // Code école optionnel pour super admin
    if (_schoolCodeController.text.isNotEmpty && _schoolName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez valider le code école')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_school_code', _schoolCodeController.text.trim().toUpperCase());
    await prefs.setString('saved_phone', phone);

    context.read<auth.AuthBloc>().add(auth.LoginWithPhoneRequested(
      phone: phone, // ⭐ ENVOIE TEL QUE TAPÉ (+2250506224449)
      password: _passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<auth.AuthBloc, auth.AuthState>(
        listener: (context, state) {
          if (state is auth.SuperAdminAuthenticated) {
            Navigator.pushReplacementNamed(context, AppRoutes.superAdminDashboard);
          } else if (state is auth.TeacherAuthenticated) {
            Navigator.pushReplacementNamed(context, AppRoutes.teacherDashboard);
          } else if (state is auth.AdminAuthenticated) {
            Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
          } else if (state is auth.ParentAuthenticated) {
            Navigator.pushReplacementNamed(context, AppRoutes.parentDashboard);
          } else if (state is auth.AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Icon(Icons.school, size: 80, color: AppTheme.violet),
                    const SizedBox(height: 16),
                    Text('EduConnect', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.violet)),
                    const SizedBox(height: 40),

                    // Code école - OPTIONNEL
                    TextFormField(
                      controller: _schoolCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Code école (optionnel)',
                        hintText: 'COL2024',
                        prefixIcon: const Icon(Icons.school_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: _isValidatingSchool 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : _schoolName != null 
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                      onChanged: _verifySchool,
                    ),
                    if (_schoolName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_schoolName!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(height: 24),

                    // ⭐ COMME AVANT : Téléphone complet avec +225
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        hintText: '+225 05 06 22 44 49', // ⭐ EXEMPLE AVEC +225
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Téléphone requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Mot de passe requis' : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mot de passe: Matricule ou Initiale+Nom',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Bouton connexion
                    BlocBuilder<auth.AuthBloc, auth.AuthState>(
                      builder: (context, state) {
                        final isLoading = state is auth.AuthLoading;
                        return ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.violet,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Se connecter', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _schoolCodeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}