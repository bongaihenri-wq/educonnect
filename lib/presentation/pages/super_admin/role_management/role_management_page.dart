// lib/presentation/pages/super_admin/role_management/role_management_page.dart
import 'package:educonnect/presentation/pages/super_admin/role_management/widgets/create_user_dialog.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../data/models/role_model.dart';
import '/../../data/repositories/role_repository.dart';
import 'widgets/role_filters.dart';
import 'widgets/role_stats_bar.dart';
import 'widgets/role_list_item.dart';
import 'widgets/create_role_dialog.dart';
import 'widgets/assign_role_dialog.dart';

class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({super.key});

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> {
  final RoleRepository _repository = RoleRepository(Supabase.instance.client);
  
  List<RoleModel> _roles = [];
  List<String> _countries = [];
  String? _selectedCountry;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final roles = await _repository.getManageableRoles(countryCode: _selectedCountry);
      final countries = await _repository.getAvailableCountries();
      
      setState(() {
        _roles = roles;
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Gestion des Rôles'),
        backgroundColor: const Color(0xFF6B4EFF),
        foregroundColor: Colors.white,
        actions: [
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
                RoleFilters(
                  countries: _countries,
                  selectedCountry: _selectedCountry,
                  onCountryChanged: (country) {
                    setState(() => _selectedCountry = country);
                    _loadData();
                  },
                ),
                RoleStatsBar(roles: _roles),
                Expanded(
                  child: _roles.isEmpty
                      ? const Center(child: Text('Aucun rôle trouvé'))
                      : ListView.builder(
                          itemCount: _roles.length,
                          itemBuilder: (context, index) {
                            final role = _roles[index];
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        backgroundColor: const Color(0xFF6B4EFF),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau rôle'),
      ),
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

  // ⭐ CORRECTION : Méthode unique et propre
  Future<void> _showCreateUserDialog(RoleModel role) async {
    List<Map<String, dynamic>> schools = [];
    try {
      final response = await Supabase.instance.client
          .from('schools')
          .select('id, name')
          .eq('is_active', true)
          .order('name');
      schools = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur chargement écoles: $e');
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateUserDialog(
        roleCode: role.code,
        roleName: role.name,
        schools: schools,
        defaultCountryCode: '225',
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Utilisateur créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData(); // ⭐ CORRIGÉ : _loadData() au lieu de _loadRoles()
    }
  }
}