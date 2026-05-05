// lib/core/services/phone_auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PhoneAuthService {
  final _supabase = Supabase.instance.client;

  /// Connexion par téléphone + mot de passe
  /// Retourne les infos user si succès
  Future<Map<String, dynamic>?> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      // Appeler la fonction RPC
      final response = await _supabase.rpc('authenticate_by_phone', params: {
        'p_phone': phone,
        'p_password': password,
      });

      if (response == null || response.isEmpty) {
        return null;
      }

      final result = response[0];
      
      if (result['success'] == true) {
        // Créer une session locale (custom)
        return {
          'user_id': result['user_id'],
          'auth_id': result['auth_id'],
          'first_name': result['first_name'],
          'last_name': result['last_name'],
          'role': result['role'],
          'school_id': result['school_id'],
        };
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Vérifier si un téléphone existe
  Future<bool> checkPhoneExists(String phone) async {
    final response = await _supabase
        .from('app_users')
        .select('id')
        .eq('phone', phone)
        .maybeSingle();
    
    return response != null;
  }
}