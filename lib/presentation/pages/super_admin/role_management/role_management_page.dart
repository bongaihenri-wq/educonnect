// lib/presentation/pages/super_admin/role_management/role_management_page.dart
import 'package:educonnect/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../data/models/role_model.dart';
import '/../../data/repositories/role_repository.dart';
import 'widgets/role_stats_bar.dart';
import 'widgets/role_list_item.dart';
import 'widgets/create_role_dialog.dart';
import 'widgets/assign_role_dialog.dart';
import 'widgets/create_user_dialog.dart';

class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({super.key});

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> {
  final RoleRepository _repository = RoleRepository(Supabase.instance.client);
  final _supabase = Supabase.instance.client;

  List<RoleModel> _allRoles = [];
  List<RoleModel> _filteredRoles = [];
  List<String> _countries = [];
  String? _selectedCountry;
  bool _isLoading = true;

  // Profil utilisateur connecté
  String? _currentUserRole;
  String? _currentUserCountry;
  String? _currentUserSchoolId;

  bool get _isSuperAdmin => _currentUserRole == 'super_admin';
  bool get _isAdmin => _currentUserRole == 'admin';
  bool get _isAssistant => _currentUserRole == 'assistant';

  /// Codes de rôles à exclure de l'affichage (parents et élèves)
  final List<String> _excludedRoleCodes = const [
    'parent',
    'student',
    'eleve',
    'enfant',
    'pupil',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile().then((_) => _loadData());
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final profile = await _supabase
            .from('app_users')
            .select('role, country_code, school_id')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null) {
          setState(() {
            _currentUserRole = profile['role'] as String?;
            _currentUserCountry = profile['country_code'] as String?;
            _currentUserSchoolId = profile['school_id'] as String?;
            if (_currentUserCountry != null && !_isSuperAdmin) {
              _selectedCountry = _currentUserCountry;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      String? filterCountry;
      if (!_isSuperAdmin && _currentUserCountry != null) {
        filterCountry = _currentUserCountry;
      } else {
        filterCountry = _selectedCountry;
      }

      final roles = await _repository.getManageableRoles(countryCode: filterCountry);
      final countries = await _repository.getAvailableCountries();

      setState(() {
        _allRoles = roles;
        // 🔒 FILTRAGE : exclure parents et élèves
        _filteredRoles = roles.where((r) {
          final code = r.code.toLowerCase().trim();
          return !_excludedRoleCodes.contains(code);
        }).toList();
        _countries = countries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Gestion des Rôles'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Utilisateurs & Rôles',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.roleUsersList);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isSuperAdmin) ...[
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    color: const Color(0xFFF8F9FE),
                    child: _buildCountryFilter(),
                  ),
                  const SizedBox(height: 8),
                ],
                if (!_isSuperAdmin && _currentUserCountry != null) ...[
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vous voyez les rôles du pays : ${_getCountryName(_currentUserCountry!)}',
                              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                RoleStatsBar(
                  roles: _filteredRoles,
                  excludedRoleCodes: _excludedRoleCodes,
                ),
                Expanded(
                  child: _filteredRoles.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, color: Colors.grey, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'Aucun rôle métier trouvé',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Les rôles Parent et Élève sont gérés dans leurs sections dédiées',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRoles.length,
                          itemBuilder: (context, index) {
                            final role = _filteredRoles[index];
                            return RoleListItem(
                              role: role,
                              onToggle: () => _toggleRole(role),
                              onAssign: () => _showAssignDialog(role),
                              onCreateUser: () => _showCreateUserDialog(role),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(),
              backgroundColor: const Color(0xFF6C63FF),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau rôle'),
            )
          : null,
    );
  }

  Widget _buildCountryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCountryChip(
            label: 'Tous',
            isSelected: _selectedCountry == null,
            onSelected: (_) {
              setState(() => _selectedCountry = null);
              _loadData();
            },
          ),
          const SizedBox(width: 8),
          ..._countries.map((country) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCountryChip(
                label: _getCountryName(country),
                isSelected: _selectedCountry == country,
                onSelected: (_) {
                  setState(() => _selectedCountry = country);
                  _loadData();
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCountryChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
        overflow: TextOverflow.ellipsis,
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF6C63FF),
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateRoleDialog(
        countries: _countries,
        repository: _repository,
        onSuccess: _loadData,
      ),
    );
  }

  void _showAssignDialog(RoleModel role) {
    showDialog(
      context: context,
      builder: (context) => AssignRoleDialog(
        role: role,
        repository: _repository,
      ),
    );
  }

  Future<void> _toggleRole(RoleModel role) async {
    final success = await _repository.toggleRoleStatus(role.id, !role.isActive);
    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(role.isActive ? 'Rôle désactivé' : 'Rôle activé'),
          backgroundColor: role.isActive ? Colors.red : Colors.green,
        ),
      );
    }
  }

  Future<void> _showCreateUserDialog(RoleModel role) async {
    List<Map<String, dynamic>> schools = [];
    try {
      var response = await _supabase
          .from('schools')
          .select('id, name, country_code')
          .eq('is_active', true)
          .order('name');

      schools = List<Map<String, dynamic>>.from(response);

      if (!_isSuperAdmin && _currentUserCountry != null) {
        schools = schools.where((s) => s['country_code'] == _currentUserCountry).toList();
      }

      if (_isAdmin && _currentUserSchoolId != null) {
        schools = schools.where((s) => s['id'] == _currentUserSchoolId).toList();
      }
    } catch (e) {
      debugPrint('Erreur chargement écoles: $e');
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateUserDialog(
        roleCode: role.code,
        roleName: role.name,
        schools: schools,
        defaultCountryCode: _currentUserCountry?.replaceFirst('+', '') ?? '225',
        isAdminSingleSchool: role.code == 'admin',
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Utilisateur créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    }
  }

  String _getCountryName(String code) {
    switch (code) {
      case '+225':
        return '🇨🇮 CI';
      case '+237':
        return '🇨🇲 CM';
      case '+221':
        return '🇸🇳 SN';
      case '+233':
        return '🇬🇭 GH';
      case '+226':
        return '🇧🇫 BF';
      case '+241':
        return '🇬🇦 GA';
      default:
        return code;
    }
  }
}