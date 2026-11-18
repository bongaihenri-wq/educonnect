// lib/features/updates/pages/publish_update_page.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/update_repository.dart';

class PublishUpdatePage extends StatefulWidget {
  const PublishUpdatePage({super.key});

  @override
  State<PublishUpdatePage> createState() => _PublishUpdatePageState();
}

class _PublishUpdatePageState extends State<PublishUpdatePage> {
  final _repo = UpdateRepository(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();

  final _versionController = TextEditingController();
  final _versionCodeController = TextEditingController();
  final _iosUrlController = TextEditingController();
  final _changelogController = TextEditingController();
  bool _isMandatory = false;
  bool _publishing = false;

  List<AppUpdateInfo> _history = [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _prefillFromInstalledVersion();
    _loadHistory();
  }

  /// ✅ Pré-remplit version + version_code depuis l'app installée
  Future<void> _prefillFromInstalledVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;
      setState(() {
        _versionController.text = info.version;
        _versionCodeController.text = (currentCode + 1).toString();
      });
    } catch (_) {/* silencieux */}
  }

  @override
  void dispose() {
    _versionController.dispose();
    _versionCodeController.dispose();
    _iosUrlController.dispose();
    _changelogController.dispose();
    super.dispose();
  }

  // ── Historique ─────────────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final list = await _repo.getAllUpdates();
      if (mounted) {
        setState(() {
          _history = list;
          _historyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  // ── Publication (URL déterministe, aucun upload) ───────────

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _publishing = true);
    try {
      final versionCode = int.parse(_versionCodeController.text.trim());
      // ✅ URL déterministe : les APK gardent des noms fixes sur la landing,
      // seul le cache-bust ?v= change à chaque release
      const baseUrl =
          'https://bongaihenri-wq.github.io/educonnect-landing/educonnect-armeabi-v7a.apk';
      final apkUrl = '$baseUrl?v=$versionCode';

      await _repo.publishUpdate(
        version: _versionController.text.trim(),
        versionCode: versionCode,
        apkUrl: apkUrl,
        iosUrl: _iosUrlController.text.trim(),
        changelog: _changelogController.text.trim(),
        isMandatory: _isMandatory,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Mise à jour publiée — bannière active pour tous'),
          backgroundColor: Colors.green));
      _iosUrlController.clear();
      _changelogController.clear();
      setState(() => _isMandatory = false);
      _prefillFromInstalledVersion();
      _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ Erreur : $e')));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publier une mise à jour'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ══ FORMULAIRE ══
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Nouvelle version',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _versionController,
                        decoration: const InputDecoration(
                          labelText: 'Version *',
                          helperText: 'Pré-remplie depuis l\'app installée',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Version obligatoire'
                            : null,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _versionCodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Version code *',
                          helperText: 'Pré-rempli (code actuel + 1) — '
                              'c\'est lui qui déclenche la bannière',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) {
                            return 'Nombre positif requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // ✅ Info : source APK (noms fixes sur la landing)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📦 Source de l\'APK',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 4),
                            Text(
                              'Avant de publier :\n'
                              '1. Build : flutter build apk --release --split-per-abi\n'
                              '2. Copier app-armeabi-v7a-release.apk vers la landing '
                              'sous le nom fixe educonnect-armeabi-v7a.apk\n'
                              '3. git push sur educonnect-landing\n\n'
                              'L\'URL est générée automatiquement (?v=code). '
                              'Aucun upload depuis l\'app.',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _iosUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL App Store iOS (optionnel)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _changelogController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Nouveautés (affichées dans la bannière)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Mise à jour obligatoire',
                            style: TextStyle(fontSize: 13)),
                        subtitle: const Text(
                            'Le bouton ✕ disparaît (bannière non dismissable)',
                            style: TextStyle(fontSize: 11)),
                        value: _isMandatory,
                        onChanged: (v) => setState(() => _isMandatory = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF)),
                        icon: _publishing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send, size: 18),
                        label: Text(_publishing
                            ? 'Publication...'
                            : 'Publier la mise à jour'),
                        onPressed: _publishing ? null : _publish,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ══ HISTORIQUE ══
            Row(
              children: [
                const Expanded(
                  child: Text('Mises à jour publiées',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _loadHistory),
              ],
            ),
            if (_historyLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('Aucune mise à jour publiée')),
              )
            else
              ..._history.map((u) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: SwitchListTile(
                      secondary: Icon(
                        u.isActive ? Icons.cloud_done : Icons.cloud_off,
                        color: u.isActive ? Colors.green : Colors.grey,
                      ),
                      title: Text('v${u.version} (code ${u.versionCode})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(
                        u.isActive
                            ? '✅ Active — bannière visible'
                            : '⏸ Désactivée',
                        style: TextStyle(
                            fontSize: 11,
                            color: u.isActive ? Colors.green : Colors.grey),
                      ),
                      value: u.isActive,
                      onChanged: u.id != null
                          ? (v) async {
                              await _repo.setUpdateActive(u.id!, v);
                              _loadHistory();
                            }
                          : null,
                    ),
                  )),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
