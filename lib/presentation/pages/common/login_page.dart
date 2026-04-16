import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs communs
  final _apiKeyController = TextEditingController();
  
  // Contrôleurs Parent
  final _phoneController = TextEditingController();
  final _matriculeController = TextEditingController();
  
  // Contrôleurs Enseignant
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isParentMode = true;
  bool _rememberMatricule = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger API Key (commun)
    final savedApiKey = prefs.getString('saved_api_key');
    if (savedApiKey != null) {
      setState(() => _apiKeyController.text = savedApiKey);
    }
    
    // Charger matricule (parent)
    if (_isParentMode) {
      final savedMatricule = prefs.getString('saved_matricule');
      if (savedMatricule != null) {
        setState(() => _matriculeController.text = savedMatricule);
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Toujours sauvegarder l'API Key
    await prefs.setString('saved_api_key', _apiKeyController.text.trim());
    
    // Sauvegarder matricule si mode parent
    if (_isParentMode && _rememberMatricule) {
      await prefs.setString('saved_matricule', _matriculeController.text.trim());
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _phoneController.dispose();
    _matriculeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    _saveData();

    final apiKey = _apiKeyController.text.trim();

    if (_isParentMode) {
      // Connexion Parent : Téléphone + Matricule + API Key
      context.read<AuthBloc>().add(
        ParentLoginRequested(
          phone: _phoneController.text.trim(),
          matricule: _matriculeController.text.trim().toUpperCase(),
          apiKey: apiKey,
        ),
      );
    } else {
      // Connexion Enseignant : Email + Password + API Key
      context.read<AuthBloc>().add(
        TeacherLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          apiKey: apiKey,
        ),
      );
    }
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    print('🔄 LoginPage - État auth: ${state.runtimeType}');
    
    if (state is TeacherAuthenticated) {
      print('✅ LoginPage - Enseignant authentifié !');
      print('🏫 École: ${state.schoolName}');
      Navigator.pushReplacementNamed(context, '/teacher/dashboard');
      
    } else if (state is ParentAuthenticated) {
      print('✅ LoginPage - Parent authentifié !');
      print('🏫 École: ${state.schoolName}');
      print('👦 Élève: ${state.studentData['first_name']} ${state.studentData['last_name']}');
      Navigator.pushReplacementNamed(context, '/parent/dashboard');
      
    } else if (state is AuthError) {
      print('❌ LoginPage - Erreur: ${state.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppTheme.rose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: _onAuthStateChanged,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.violet, AppTheme.violetDark],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.violet.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Titre
                  const Text(
                    'EduConnect',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.nightBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Votre école connectée',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.nightBlueLight.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // CHAMP API KEY (Commun aux deux modes)
                  Container(
                    padding: const EdgeInsets.all(16),
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
                            Icon(Icons.key, color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Clé API de l\'école',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _apiKeyController,
                          decoration: InputDecoration(
                            hintText: 'sk_live_...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer la clé API';
                            }
                            if (!value.startsWith('sk_live_')) {
                              return 'Format invalide (sk_live_...)';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // SÉLECTEUR DE MODE
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
                                color: _isParentMode ? AppTheme.violet : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isParentMode ? [
                                  BoxShadow(
                                    color: AppTheme.violet.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ] : null,
                              ),
                              child: Text(
                                '👨‍👩‍👧 Parent',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isParentMode ? Colors.white : AppTheme.nightBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isParentMode = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !_isParentMode ? AppTheme.violet : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isParentMode ? [
                                  BoxShadow(
                                    color: AppTheme.violet.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ] : null,
                              ),
                              child: Text(
                                '👨‍🏫 Enseignant',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_isParentMode ? Colors.white : AppTheme.nightBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // FORMULAIRE SELON LE MODE
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isParentMode ? _buildParentForm() : _buildTeacherForm(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // BOUTON CONNEXION
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is AuthLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isParentMode ? AppTheme.teal : AppTheme.violet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: (_isParentMode ? AppTheme.teal : AppTheme.violet).withOpacity(0.4),
                        ),
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Se connecter',
                                style: const TextStyle(
                                  fontSize: 17, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  

                  Center(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.help_outline, size: 18),
                      label: const Text('Besoin d\'aide ?'),
                    ),
                  ),
                ],
              ),
            ),
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
        border: Border.all(color: AppTheme.teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connexion Parent',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.tealDark,
            ),
          ),
          const SizedBox(height: 16),
          
          // Téléphone
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Numéro de téléphone',
              hintText: '06 98 76 54 32',
              prefixIcon: const Icon(Icons.phone_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre numéro';
              }
              if (value.replaceAll(' ', '').length < 10) {
                return 'Numéro trop court';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Matricule
          TextFormField(
            controller: _matriculeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Matricule de l\'enfant',
              hintText: '2024001',
              prefixIcon: const Icon(Icons.badge_outlined),
              helperText: 'Code fourni par l\'école',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le matricule';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          
          // Mémoriser matricule
          Row(
            children: [
              Checkbox(
                value: _rememberMatricule,
                onChanged: (value) {
                  setState(() => _rememberMatricule = value ?? true);
                },
                activeColor: AppTheme.teal,
              ),
              const Text(
                'Mémoriser le matricule',
                style: TextStyle(fontSize: 14),
              ),
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
        color: AppTheme.violetPale,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connexion Enseignant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.violetDark,
            ),
          ),
          const SizedBox(height: 16),
          
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'professeur@ecole.fr',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!value.contains('@')) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Mot de passe
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre mot de passe';
              }
              if (value.length < 6) {
                return 'Mot de passe trop court';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          
          // Mot de passe oublié
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
        ],
      ),
    );
  }
}
