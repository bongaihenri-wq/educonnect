// lib/features/updates/widgets/update_banner.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/update_repository.dart';

/// Bannière "Mise à jour disponible" — auto-détectrice, dismissable,
/// adaptée à la plateforme (Android → APK, iOS → App Store si lien fourni).
/// À insérer en UNE ligne en haut de chaque home page.
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key});
  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  AppUpdateInfo? _update;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;

      final latest =
          await UpdateRepository(Supabase.instance.client).getLatestUpdate();
      if (latest == null || latest.versionCode <= currentCode) return;

      // ✅ iOS : pas d'APK — la bannière ne s'affiche QUE si un lien iOS existe
      if (Platform.isIOS && (latest.iosUrl == null || latest.iosUrl!.isEmpty)) {
        return;
      }

      // Ne pas re-afficher une MAJ déjà dismissée (sauf si obligatoire)
      final prefs = await SharedPreferences.getInstance();
      final dismissedFor = prefs.getInt('update_dismissed_code') ?? 0;
      if (!latest.isMandatory && dismissedFor >= latest.versionCode) {
        setState(() => _dismissed = true);
        return;
      }
      if (mounted) setState(() => _update = latest);
    } catch (_) {/* silencieux — jamais bloquant */}
  }

  Future<void> _download() async {
    // ✅ Plateforme : Android → APK, iOS → App Store
    final raw = Platform.isIOS ? _update!.iosUrl! : _update!.apkUrl;
    final url = Uri.parse(raw);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('update_dismissed_code', _update!.versionCode);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_update == null || _dismissed) return const SizedBox.shrink();

    final isIOS = Platform.isIOS;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF8B7CFF)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIOS ? Icons.apple : Icons.system_update_alt,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Mise à jour ${_update!.version} disponible',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              if (!_update!.isMandatory)
                GestureDetector(
                  onTap: _dismiss,
                  child:
                      const Icon(Icons.close, color: Colors.white70, size: 18),
                ),
            ],
          ),
          if (_update!.changelog != null && _update!.changelog!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_update!.changelog!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6C63FF)),
              icon: Icon(isIOS ? Icons.open_in_new : Icons.download, size: 16),
              label: Text(
                  isIOS
                      ? 'Ouvrir dans l\'App Store'
                      : 'Télécharger et installer',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _download,
            ),
          ),
        ],
      ),
    );
  }
}
