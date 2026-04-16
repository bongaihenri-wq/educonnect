import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '/presentation/blocs/auth_bloc/auth_bloc.dart' as auth;

class SchoolLoginPage extends StatefulWidget {
  const SchoolLoginPage({super.key});

  @override
  State<SchoolLoginPage> createState() => _SchoolLoginPageState();
}

class _SchoolLoginPageState extends State<SchoolLoginPage> {
  final _schoolCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _rememberSchool = true;
  bool _rememberMatricule = true;
  bool _isParentMode = true;
  bool _isLoading = false;
  String? _schoolName;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final savedSchool = prefs.getString('saved_school_code');
    final savedSchoolName = prefs.getString('saved_school_name');
    
    if (savedSchool != null) {
      setState(() {
        _schoolCodeController.text = savedSchool;
        _schoolName = savedSchoolName;
      });
      await _verifySchool(savedSchool, save: false);
    }
    
    final savedMatricule = prefs.getString('saved_matricule');
    if (savedMatricule != null) {
      setState(() => _matriculeController.text = savedMatricule);
    }
  }

  Future<void> _verifySchool(String code, {bool save = true}) async {
    if (code.length < 3) return;
    
    try {
      final school = await Supabase.instance.client
          .from('schools')
          .select('id, name, api_key, school_code')
          .ilike('school_code', code)
          .eq('is_active', true)
          .maybeSingle();

      if (school != null) {
        setState(() {
          _schoolName = school['name'];
          _apiKey = school['api_key'];
        });
        
        if (save && _rememberSchool) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_school_code', code.toUpperCase());
          await prefs.setString('saved_school_name', school['name']);
        }
      } else {
        setState(() {
          _schoolName = null;
          _apiKey = null;
        });
      }
    } catch (e) {
      print('Erreur vérification école: $e');
    }
  }

  void _login() async {
    if (_apiKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vérifiez le code de l\'école'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_rememberSchool) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_school_code', _schoolCodeController.text.trim().toUpperCase());
    }
    if (_isParentMode && _rememberMatricule) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_matricule', _matriculeController.text.trim());
    }

    setState(() => _isLoading = true);

    if (_isParentMode) {
      context.read<auth.AuthBloc>().add(auth.ParentLoginRequested(
        phone: _phoneController.text.trim(),
        matricule: _matriculeController.text.trim().toUpperCase(),
        apiKey: _apiKey!,
      ));
    } else {
      context.read<auth.AuthBloc>().add(auth.TeacherLoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        apiKey: _apiKey!,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.violet, AppTheme.violetDark],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(Icons.school, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'EduConnect',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.nightBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ═══════════════════════════════════════════════════
              // ═══ BOUTON TEST IMPORT (TEMPORAIRE) ════════════════
              // ═══════════════════════════════════════════════════
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/admin/import'),
                icon: const Icon(Icons.upload_file),
                label: const Text(
                  'TEST Import (Admin)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Mon école',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: _schoolCodeController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: 'Code école',
                        hintText: 'ex: COL2024',
                        helperText: 'Exemple: COL2024 pour Collège Victor Hugo',
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                        ),
                      ),
                      onChanged: (value) async {
                        if (value.length >= 3) {
                          await _verifySchool(value);
                        }
                      },
                    ),
                    
                    if (_schoolName != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _schoolName!,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberSchool,
                          onChanged: (v) => setState(() => _rememberSchool = v ?? true),
                          activeColor: Colors.amber.shade700,
                        ),
                        Text(
                          'Mémoriser mon école',
                          style: TextStyle(fontSize: 13, color: Colors.amber.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.bisDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isParentMode = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isParentMode ? AppTheme.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '👨‍👩‍👧 Parent',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isParentMode ? Colors.white : AppTheme.nightBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isParentMode = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_isParentMode ? AppTheme.violet : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '👨‍🏫 Enseignant',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isParentMode ? Colors.white : AppTheme.nightBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isParentMode ? _buildParentForm() : _buildTeacherForm(),
              ),
              
              const SizedBox(height: 32),
              
              BlocListener<auth.AuthBloc, auth.AuthState>(
                listener: (context, state) {
                  setState(() => _isLoading = false);
                  
                  if (state is auth.AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppTheme.rose,
                      ),
                    );
                  } else if (state is auth.ParentAuthenticated) {
                    Navigator.pushReplacementNamed(context, '/parent/dashboard');
                  } else if (state is auth.TeacherAuthenticated) {
                    Navigator.pushReplacementNamed(context, '/teacher/dashboard');
                  }
                },
                child: ElevatedButton(
                  onPressed: (_apiKey == null || _isLoading) ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isParentMode ? AppTheme.teal : AppTheme.violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Se connecter',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentForm() {
    return Container(
      key: const ValueKey('parent'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Téléphone',
              hintText: '06 98 76 54 32',
              prefixIcon: const Icon(Icons.phone),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _matriculeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Matricule enfant',
              hintText: '2024001',
              prefixIcon: const Icon(Icons.badge),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          Row(
            children: [
              Checkbox(
                value: _rememberMatricule,
                onChanged: (v) => setState(() => _rememberMatricule = v ?? true),
                activeColor: AppTheme.teal,
              ),
              const Text('Mémoriser le matricule'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherForm() {
    return Container(
      key: const ValueKey('teacher'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.violet.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'prof@ecole.fr',
              prefixIcon: const Icon(Icons.email),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
