// lib/presentation/pages/super_admin/role_management/role_users_list_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RoleUsersListPage extends StatefulWidget {
  const RoleUsersListPage({super.key});

  @override
  State<RoleUsersListPage> createState() => _RoleUsersListPageState();
}

class _RoleUsersListPageState extends State<RoleUsersListPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _schools = [];

  String? _filterRole;
  String? _filterCountry;

  /// 🔒 Rôles à exclure de l'affichage (parents et élèves)
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Utilisateurs (100 derniers)
      final usersResult = await _supabase
          .from('app_users')
          .select('id, first_name, last_name, phone, email, role, school_id, country_code, created_at, is_active')
          .order('created_at', ascending: false)
          .limit(100);

      // 2. Rôles (définitions)
      final rolesResult = await _supabase
          .from('roles')
          .select('id, code, name, country_code')
          .limit(100);

      // 3. Écoles
      final schoolsResult = await _supabase
          .from('schools')
          .select('id, name')
          .limit(100);

      final usersList = List<Map<String, dynamic>>.from(usersResult);
      final rolesList = List<Map<String, dynamic>>.from(rolesResult);
      final schoolsList = List<Map<String, dynamic>>.from(schoolsResult);

      // 🔒 FILTRAGE : exclure parents et élèves AVANT assemblage
      final filteredUsersList = usersList.where((u) {
        final role = (u['role'] as String? ?? '').toLowerCase().trim();
        return !_excludedRoleCodes.contains(role);
      }).toList();

      // Maps rapides
      final rolesByCode = {for (var r in rolesList) r['code'] as String: r};
      final schoolsById = {for (var s in schoolsList) s['id'] as String: s};

      // Assembler
      final assembled = filteredUsersList.map((u) {
        final roleCode = u['role'] as String? ?? '—';
        final roleDef = rolesByCode[roleCode];
        final schoolId = u['school_id'] as String?;
        final school = schoolId != null ? schoolsById[schoolId] : null;
        final createdAt = u['created_at'] != null
            ? DateTime.tryParse(u['created_at'].toString())
            : null;

        return {
          ...u,
          'role_name': roleDef?['name'] ?? roleCode,
          'role_color': _roleColor(roleCode),
          'school_name': school?['name'] ?? (schoolId != null ? 'École inconnue' : 'Toutes'),
          'country_label': _countryLabel(u['country_code'] as String?),
        };
      }).toList();

      // Extraire filtres uniques
      final uniqueRoles = assembled.map((u) => u['role'] as String?).where((r) => r != null).toSet().toList();
      final uniqueCountries = assembled.map((u) => u['country_code'] as String?).where((c) => c != null).toSet().toList();

      setState(() {
        _users = assembled;
        _roles = uniqueRoles.map((r) => {'code': r, 'name': rolesByCode[r]?['name'] ?? r}).toList();
        _schools = uniqueCountries.map((c) => {'code': c, 'label': _countryLabel(c)}).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _users.where((u) {
      if (_filterRole != null && u['role'] != _filterRole) return false;
      if (_filterCountry != null && u['country_code'] != _filterCountry) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Utilisateurs & Rôles'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                // 🔒 Padding bottom suffisant pour voir les éléments en bas
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 16),
                    _filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : _buildUsersList(),
                    // 🔒 Espace supplémentaire en bas
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsRow() {
    final total = _users.length;
    final active = _users.where((u) => u['is_active'] == true).length;
    final inactive = total - active;

    return Row(
      children: [
        Expanded(child: _buildKpi('Total', '$total', Icons.people, const Color(0xFF6C63FF))),
        const SizedBox(width: 8),
        Expanded(child: _buildKpi('Actifs', '$active', Icons.check_circle, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildKpi('Inactifs', '$inactive', Icons.block, Colors.red)),
      ],
    );
  }

  Widget _buildKpi(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filtres', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tous rôles', null, _filterRole, (v) => setState(() => _filterRole = v)),
              ..._roles.map((r) {
                final code = r['code'] as String;
                return _buildFilterChip(
                  r['name'] ?? code,
                  code,
                  _filterRole,
                  (v) => setState(() => _filterRole = v),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tous pays', null, _filterCountry, (v) => setState(() => _filterCountry = v)),
              ..._schools.map((c) {
                final code = c['code'] as String;
                return _buildFilterChip(
                  c['label'] ?? code,
                  code,
                  _filterCountry,
                  (v) => setState(() => _filterCountry = v),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? value, String? groupValue, Function(String?) onSelected) {
    final isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.grey[700]),
          overflow: TextOverflow.ellipsis,
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(value),
        selectedColor: const Color(0xFF6C63FF),
        backgroundColor: Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, color: Colors.grey, size: 24),
          SizedBox(width: 8),
          Text('Aucun utilisateur trouvé', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return Column(
      children: _filteredUsers.map((u) {
        final name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
        final phone = u['phone'] ?? '—';
        final email = u['email'] ?? '—';
        final roleName = u['role_name'] as String;
        final roleColor = u['role_color'] as Color;
        final schoolName = u['school_name'] as String;
        final countryLabel = u['country_label'] as String;
        final isActive = u['is_active'] == true;
        final createdAt = u['created_at'] != null
            ? DateTime.tryParse(u['created_at'].toString())
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: roleColor.withOpacity(0.15),
                      child: Text(
                        name.isNotEmpty ? '${name[0]}' : '?',
                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : 'Sans nom',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2D3142)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            phone,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        isActive ? 'ACTIF' : 'INACTIF',
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                // Ligne infos — Wrap pour éviter overflow horizontal
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge(roleName, roleColor, Icons.work_outline),
                    _buildBadge(schoolName, Colors.blue, Icons.school_outlined),
                    _buildBadge(countryLabel, Colors.orange, Icons.flag_outlined),
                  ],
                ),
                if (email != '—' && email.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '📧 $email',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Créé le ${DateFormat('dd/MM/yyyy').format(createdAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          // 🔒 Flexible pour éviter le dépassement de pixels
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String code) {
    switch (code) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      case 'assistant':
        return const Color(0xFF6C63FF);
      case 'teacher':
        return Colors.blue;
      case 'parent':
        return Colors.teal;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _countryLabel(String? code) {
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
        return code ?? '—';
    }
  }
}