// lib/features/updates/pages/publish_update_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
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

  // ✅ APK sélectionné localement (upload automatique à la publication)
  String? _apkFileName;
  Uint8List? _apkBytes;

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

  // ── Sélection APK ──────────────────────────────────────────

  Future<void> _pickApk() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _apkFileName = file.name;
      _apkBytes = file.bytes;
    });
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

  // ── Publication (upload APK inclus) ────────────────────────

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_apkBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sélectionnez le fichier APK à publier'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _publishing = true);
    try {
      // 1. Upload APK → URL publique automatique
      final versionCode = int.parse(_versionCodeController.text.trim());
      final fileName =
          'app-v${_versionController.text.trim()}-$versionCode.apk';
      final apkUrl = await _repo.uploadApk(_apkBytes!, fileName);

      // 2. Publier la MAJ avec l'URL obtenue
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
      setState(() {
        _isMandatory = false;
        _apkFileName = null;
        _apkBytes = null;
      });
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

                      // ✅ Pré-rempli (modifiable)
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

                      // ✅ Pré-rempli = code actuel + 1
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

                      // ✅ Sélection APK → upload automatique à la publication
                      OutlinedButton.icon(
                        icon: const Icon(Icons.android, size: 18),
                        label: Text(_apkFileName == null
                            ? 'Choisir le fichier APK *'
                            : '✅ $_apkFileName'),
                        onPressed: _publishing ? null : _pickApk,
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
                            ? 'Upload + publication...'
                            : 'Publier la mise à jour'),
                        onPressed: _publishing ? null : _publish,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
