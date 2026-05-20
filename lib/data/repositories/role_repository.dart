// lib/data/repositories/role_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/role_model.dart';

class RoleRepository {
  final SupabaseClient _client;

  RoleRepository(this._client);

  /// Récupérer les rôles (filtré par pays si spécifié)
 Future<List<RoleModel>> getRoles({String? countryCode}) async {
    try {
      // ✅ DEBUG : Vérifier l'état de la session
      final session = _client.auth.currentSession;
      final user = _client.auth.currentUser;
      print('🔍 DEBUG Supabase session: ${session != null ? 'ACTIVE' : 'NULL'}');
      print('🔍 DEBUG Supabase user: ${user != null ? user.id : 'NULL'}');
      
      final response = await _client
          .from('roles')
          .select('*')
          .order('level', ascending: false);
      
      print('🔍 DEBUG Supabase response: $response');
      
      if (response == null) {
        print('🔍 DEBUG response is NULL');
        return [];
      }
      
      final allData = response as List<dynamic>? ?? [];
      print('🔍 DEBUG allData length: ${allData.length}');
      
      final allRoles = allData.map((json) => RoleModel.fromJson(json as Map<String, dynamic>)).toList();
      
      if (countryCode == null) return allRoles;
      
      return allRoles.where((role) {
        final isMatch = role.countryCode == countryCode || role.countryCode == null || role.countryCode!.isEmpty;
        return isMatch;
      }).toList();
    } catch (e, stackTrace) {
      print('❌ DEBUG getRoles ERROR: $e');
      print('❌ DEBUG stackTrace: $stackTrace');
      return [];
    }
  }

  /// Rôles modifiables par Super Admin
  Future<List<RoleModel>> getManageableRoles({String? countryCode}) async {
    print('🔍 DEBUG getManageableRoles called with countryCode=$countryCode');
    
    final allRoles = await getRoles(countryCode: countryCode);
    print('🔍 DEBUG getRoles returned: ${allRoles.length} roles');
    
    final filtered = allRoles.where((r) {
      final keep = r.code != 'super_admin' && !['teacher', 'parent', 'student'].contains(r.code);
      print('🔍 DEBUG filtering ${r.code}: keep=$keep');
      return keep;
    }).toList();
    
    print('🔍 DEBUG filtered result: ${filtered.length} roles');
    return filtered;
  }


  /// Créer un rôle
  Future<Map<String, dynamic>> createRole({
    required String code,
    required String name,
    required int level,
    String? countryCode,
    String? schoolId,
    String? createdBy,
  }) async {
    try {
      final response = await _client.rpc('create_role', params: {
        'p_code': code,
        'p_name': name,
        'p_level': level,
        'p_country_code': countryCode,
        'p_school_id': schoolId,
        'p_created_by': createdBy,
      });
      
      if (response == null) return {'success': false, 'message': 'Réponse null'};
      if (response is List && response.isNotEmpty) return response[0] as Map<String, dynamic>;
      if (response is Map<String, dynamic>) return response;
      return {'success': false, 'message': 'Réponse invalide'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> toggleRoleStatus(String roleId, bool isActive) async {
    try {
      await _client.from('roles').update({'is_active': isActive}).eq('id', roleId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getAvailableCountries() async {
    final response = await _client.from('schools').select('country_code');
    if (response == null) return [];
    
    final data = response as List<dynamic>? ?? [];
    final countries = <String>{};
    for (final s in data) {
      final code = (s as Map<String, dynamic>)['country_code']?.toString();
      if (code != null && code.isNotEmpty && code != 'null') countries.add(code);
    }
    return countries.toList()..sort();
  }

  Future<List<Map<String, dynamic>>> getSchoolsByCountry(String countryCode) async {
    final response = await _client
        .from('schools')
        .select('id, name, country_code')
        .eq('country_code', countryCode)
        .order('name');
    
    if (response == null) return [];
    final data = response as List<dynamic>? ?? [];
    return data.map((s) => s as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> findUserByPhone(String phone) async {
    final response = await _client
        .from('app_users')
        .select('id, first_name, last_name')
        .eq('phone', phone)
        .limit(1);
    
    if (response == null) return [];
    final data = response as List<dynamic>? ?? [];
    return data.map((s) => s as Map<String, dynamic>).toList();
  }
}