// lib/services/update_service.dart
import 'dart:developer' as developer;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Résultat de la vérification de version
class VersionCheckResult {
  final bool hasUpdate;
  final int? currentVersion;
  final int? latestVersion;
  final String? versionName;
  final String? apkUrl;
  final String? apkHash;
  final bool isMandatory;
  final String? changelog;
  final int? fileSize;
  final String? versionId;

  const VersionCheckResult._({
    required this.hasUpdate,
    this.currentVersion,
    this.latestVersion,
    this.versionName,
    this.apkUrl,
    this.apkHash,
    this.isMandatory = false,
    this.changelog,
    this.fileSize,
    this.versionId,
  });

  factory VersionCheckResult.upToDate() => const VersionCheckResult._(hasUpdate: false);

  factory VersionCheckResult.updateAvailable({
    required int currentVersion,
    required int latestVersion,
    required String versionName,
    required String apkUrl,
    String? apkHash,
    bool isMandatory = false,
    String? changelog,
    int? fileSize,
    String? versionId,
  }) => VersionCheckResult._(
    hasUpdate: true,
    currentVersion: currentVersion,
    latestVersion: latestVersion,
    versionName: versionName,
    apkUrl: apkUrl,
    apkHash: apkHash,
    isMandatory: isMandatory,
    changelog: changelog,
    fileSize: fileSize,
    versionId: versionId,
  );
}

/// Service de gestion des mises à jour OTA
class UpdateService {
  final _supabase = Supabase.instance.client;

  /// Vérifie si une mise à jour est disponible
  Future<VersionCheckResult> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 0;

      developer.log('UpdateService: Current version code = $currentVersion');

      final response = await _supabase.rpc(
        'check_app_version',
        params: {
          'p_platform': 'android',
          'p_current_version': currentVersion,
        },
      );

      developer.log('UpdateService: RPC response = $response');

      if (response == null || response.isEmpty) {
        developer.log('UpdateService: No response from RPC');
        return VersionCheckResult.upToDate();
      }

      final data = response[0] as Map<String, dynamic>;

      if (data['has_update'] != true) {
        developer.log('UpdateService: No update available');
        return VersionCheckResult.upToDate();
      }

      developer.log('UpdateService: Update available! v${data['latest_version_name']}');

      return VersionCheckResult.updateAvailable(
        currentVersion: currentVersion,
        latestVersion: data['latest_version_code'] as int,
        versionName: data['latest_version_name'] as String,
        apkUrl: data['apk_url'] as String,
        apkHash: data['apk_hash'] as String?,
        isMandatory: data['is_mandatory'] as bool? ?? false,
        changelog: data['changelog'] as String?,
        fileSize: data['file_size_bytes'] as int?,
        versionId: data['id'] as String?,
      );
    } catch (e, stack) {
      developer.log('UpdateService.checkForUpdate error: $e\n$stack');
      return VersionCheckResult.upToDate();
    }
  }

  /// Incrémente le compteur de téléchargement
  Future<void> incrementDownloadCount(String versionId) async {
    try {
      await _supabase.rpc('increment_download_count', params: {
        'p_version_id': versionId,
      });
      developer.log('UpdateService: Download count incremented');
    } catch (e) {
      developer.log('UpdateService.incrementDownloadCount error: $e');
    }
  }

  /// Formatte la taille en lisible
  static String formatFileSize(int? bytes) {
    if (bytes == null) return 'Inconnue';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}