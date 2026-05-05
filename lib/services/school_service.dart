// lib/core/services/school_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchoolService {
  static String? _currentSchoolId;
  static String? _currentSchoolCode;
  static String? _currentSchoolName;
  static String? _currentApiKey;

  static String? get currentSchoolId => _currentSchoolId;
  static String? get currentSchoolCode => _currentSchoolCode;
  static String? get currentSchoolName => _currentSchoolName;
  static String? get currentApiKey => _currentApiKey;
  
  static bool get isConfigured => _currentSchoolId != null;

  // ⭐ NOUVEAU : Méthode d'initialisation complète
  static Future<bool> registerNewSchool({
    required String name,
    required String code,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Vérifier si l'école existe déjà
      final existing = await supabase
          .from('schools')
          .select()
          .eq('school_code', code)
          .maybeSingle();
          
      if (existing != null) {
        // École existe déjà, on la configure localement
        await setSchool(
          id: existing['id'],
          code: existing['school_code'],
          name: existing['name'],
          apiKey: existing['api_key'],
        );
        return true;
      }

      // Créer une nouvelle école dans Supabase
      final response = await supabase
          .from('schools')
          .insert({
            'name': name,
            'school_code': code,
            'api_key': 'sk_live_${DateTime.now().millisecondsSinceEpoch}',
          })
          .select()
          .single();

      // Sauvegarder localement
      await setSchool(
        id: response['id'],
        code: response['school_code'],
        name: response['name'],
        apiKey: response['api_key'],
      );

      return true;
    } catch (e) {
      print('❌ Erreur registerNewSchool: $e');
      return false;
    }
  }

  // Configuration manuelle (méthode existante)
  static Future<void> setSchool({
    required String id,
    required String code,
    required String name,
    String? apiKey,
  }) async {
    _currentSchoolId = id;
    _currentSchoolCode = code;
    _currentSchoolName = name;
    _currentApiKey = apiKey;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('school_id', id);
    await prefs.setString('school_code', code);
    await prefs.setString('school_name', name);
    if (apiKey != null) {
      await prefs.setString('school_api_key', apiKey);
    }
  }

  // Chargement depuis SharedPreferences
  static Future<void> loadSchool() async {
    final prefs = await SharedPreferences.getInstance();
    _currentSchoolId = prefs.getString('school_id');
    _currentSchoolCode = prefs.getString('school_code');
    _currentSchoolName = prefs.getString('school_name');
    _currentApiKey = prefs.getString('school_api_key');
  }

  // Nettoyage
  static Future<void> clearSchool() async {
    _currentSchoolId = null;
    _currentSchoolCode = null;
    _currentSchoolName = null;
    _currentApiKey = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('school_id');
    await prefs.remove('school_code');
    await prefs.remove('school_name');
    await prefs.remove('school_api_key');
  }
}