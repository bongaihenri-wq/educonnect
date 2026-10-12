import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class AppUpdateInfo {
  final String? id;
  final String version;
  final int versionCode;
  final String apkUrl;
  final String? iosUrl;
  final String? changelog;
  final bool isMandatory;
  final bool isActive; // ✅ AJOUTÉ

  AppUpdateInfo({
    this.id,
    required this.version,
    required this.versionCode,
    required this.apkUrl,
    this.iosUrl,
    this.changelog,
    required this.isMandatory,
    required this.isActive, // ✅ AJOUTÉ
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> j) => AppUpdateInfo(
        id: j['id'] as String?,
        version: j['version'] as String,
        versionCode: j['version_code'] as int,
        apkUrl: j['apk_url'] as String,
        iosUrl: j['ios_url'] as String?,
        changelog: j['changelog'] as String?,
        isMandatory: j['is_mandatory'] as bool? ?? false,
        isActive: j['is_active'] as bool? ?? true, // ✅ AJOUTÉ
      );
}

class UpdateRepository {
  final SupabaseClient _client;
  UpdateRepository(this._client);

  /// Dernière MAJ active (null si aucune)
  Future<AppUpdateInfo?> getLatestUpdate() async {
    final rows = await _client
        .from('app_updates')
        .select()
        .eq('is_active', true)
        .order('version_code', ascending: false)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : AppUpdateInfo.fromJson(list.first);
  }

  /// Publier (ou préparer) une mise à jour
  Future<void> publishUpdate({
    required String version,
    required int versionCode,
    required String apkUrl,
    String? iosUrl,
    String? changelog,
    bool isMandatory = false,
  }) async {
    await _client.from('app_updates').insert({
      'version': version,
      'version_code': versionCode,
      'apk_url': apkUrl,
      if (iosUrl != null && iosUrl.isNotEmpty) 'ios_url': iosUrl,
      if (changelog != null && changelog.isNotEmpty) 'changelog': changelog,
      'is_mandatory': isMandatory,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Activer / désactiver une MAJ (effet immédiat sur toutes les bannières)
  Future<void> setUpdateActive(String id, bool active) async {
    await _client
        .from('app_updates')
        .update({'is_active': active}).eq('id', id);
  }

  /// Historique des MAJ publiées
  Future<List<AppUpdateInfo>> getAllUpdates() async {
    final rows = await _client
        .from('app_updates')
        .select()
        .order('version_code', ascending: false)
        .limit(20);
    return (rows as List)
        .map((j) => AppUpdateInfo.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  /// Upload un APK vers Supabase Storage et retourne son URL publique
  Future<String> uploadApk(Uint8List bytes, String fileName) async {
    final path = 'releases/$fileName';
    await _client.storage.from('apk-updates').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('apk-updates').getPublicUrl(path);
  }
}
