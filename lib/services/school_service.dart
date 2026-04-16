import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service de gestion de l'école et de l'API Key
/// 
/// Stockage persistant de l'API key et configuration
/// de la session Supabase pour l'isolation des données.
class SchoolService {
  static const String _apiKeyKey = 'school_api_key';
  static const String _schoolIdKey = 'school_id';
  static const String _schoolNameKey = 'school_name';
  
  static String? _cachedApiKey;
  static String? _cachedSchoolId;
  static String? _cachedSchoolName;

  /// Récupère l'API key en cache ou depuis le stockage local
  static Future<String?> getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedApiKey = prefs.getString(_apiKeyKey);
    return _cachedApiKey;
  }

  /// Récupère l'ID de l'école en cache
  static String? get currentSchoolId => _cachedSchoolId;

  /// Récupère le nom de l'école en cache
  static String? get currentSchoolName => _cachedSchoolName;

  /// Définit l'API key et configure la session
  /// 
  /// [apiKey] La clé API de l'école (ex: sk_live_...)
  /// Retourne true si l'API key est valide, false sinon
  static Future<bool> setApiKey(String apiKey) async {
    try {
      print('🔑 SchoolService - Configuration API Key: $apiKey');

      // 1. Vérifier l'API key via Supabase RPC
      final result = await Supabase.instance.client
          .rpc('get_school_id_by_api_key', params: {
        'p_api_key': apiKey,
      });

      if (result == null) {
        print('❌ SchoolService - API Key invalide');
        return false;
      }

      final schoolId = result as String;
      
      // 2. Récupérer les infos de l'école
      final schoolData = await Supabase.instance.client
          .from('schools')
          .select('name, is_active')
          .eq('id', schoolId)
          .single();

      if (schoolData['is_active'] != true) {
        print('❌ SchoolService - École inactive');
        return false;
      }

      // 3. Configurer la session Supabase
      await Supabase.instance.client.rpc('set_current_school', params: {
        'p_api_key': apiKey,
      });

      // 4. Sauvegarder en local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyKey, apiKey);
      await prefs.setString(_schoolIdKey, schoolId);
      await prefs.setString(_schoolNameKey, schoolData['name']);

      // 5. Mettre en cache
      _cachedApiKey = apiKey;
      _cachedSchoolId = schoolId;
      _cachedSchoolName = schoolData['name'];

      print('✅ SchoolService - École configurée: ${schoolData['name']} ($schoolId)');
      return true;

    } catch (e) {
      print('💥 SchoolService - Erreur: $e');
      return false;
    }
  }

  /// Restaure la session depuis le stockage local
  /// 
  /// À appeler au démarrage de l'app
  static Future<bool> restoreSession() async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      print('⚠️ SchoolService - Aucune API key stockée');
      return false;
    }
    return await setApiKey(apiKey);
  }

  /// Efface toutes les données de session
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
    await prefs.remove(_schoolIdKey);
    await prefs.remove(_schoolNameKey);
    
    _cachedApiKey = null;
    _cachedSchoolId = null;
    _cachedSchoolName = null;
    
    print('🧹 SchoolService - Session effacée');
  }

  /// Vérifie si une session est active
  static bool get isConfigured => _cachedApiKey != null && _cachedSchoolId != null;

  /// Retourne les headers pour les requêtes HTTP directes (si besoin)
  static Map<String, String> get headers => {
    'X-School-API-Key': _cachedApiKey ?? '',
  };
}
