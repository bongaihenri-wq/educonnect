import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme.dart';

class CredentialsPage extends StatelessWidget {
  final List<Map<String, dynamic>> credentials;
  final String schoolCode;

  const CredentialsPage({
    super.key,
    required this.credentials,
    required this.schoolCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Mots de passe générés'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Tout copier',
            onPressed: () => _copyAll(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
            onPressed: () => _shareAll(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: credentials.length,
              itemBuilder: (context, index) {
                final cred = credentials[index];
                return _buildCredentialCard(context, cred);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.violet, Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'École: $schoolCode',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${credentials.length} comptes créés',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Conservez ces informations en lieu sûr',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialCard(BuildContext context, Map<String, dynamic> cred) {
    final type = cred['type']?.toString() ?? 'user';
    final name = cred['name']?.toString() ?? 'Inconnu';
    final email = cred['email']?.toString() ?? '';
    final password = cred['password']?.toString() ?? '';
    final phone = cred['phone']?.toString() ?? '';

    final typeColor = type == 'parent' ? Colors.blue : Colors.orange;
    final typeIcon = type == 'parent' ? Icons.family_restroom : Icons.school;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        type == 'parent' ? 'Parent' : 'Enseignant',
                        style: TextStyle(
                          fontSize: 12,
                          color: typeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.email, 'Email', email),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.key, 'Mot de passe', password, isPassword: true),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, 'Téléphone', phone),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareViaWhatsApp(context, name, email, password, phone),
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: Colors.green.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareViaSMS(context, name, email, password, phone),
                    icon: const Icon(Icons.sms, size: 18),
                    label: const Text('SMS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: 'Email: $email\nMot de passe: $password',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copié !')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.violet,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isPassword = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isPassword ? FontWeight.bold : FontWeight.normal,
              fontFamily: isPassword ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  void _copyAll(BuildContext context) {
    final text = credentials.map((c) {
      return '''
${c['name']}
Type: ${c['type']}
Email: ${c['email']}
Mot de passe: ${c['password']}
Téléphone: ${c['phone'] ?? 'N/A'}
-------------------''';
    }).join('\n');

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tous les credentials copiés !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareAll(BuildContext context) {
    final text = credentials.map((c) {
      return '${c['name']}: ${c['email']} / ${c['password']}';
    }).join('\n');

    Share.share(
      '''Rapport EduConnect - École $schoolCode

$text''',
      subject: 'Credentials EduConnect $schoolCode',
    );
  }

  void _shareViaWhatsApp(BuildContext context, String name, String email, String password, String phone) {
    final message = 
      'Bonjour $name,\n\n'
      'Votre compte EduConnect est créé :\n'
      '• Email: $email\n'
      '• Mot de passe: $password\n\n'
      'Téléchargez l\'application EduConnect pour suivre la scolarité.\n\n'
      'Cordialement,\nL\'équipe EduConnect';

    // Ouvre WhatsApp avec le message pré-rempli
    // Note: Nécessite le package url_launcher pour les liens directs
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copié. Ouvrez WhatsApp et collez.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _shareViaSMS(BuildContext context, String name, String email, String password, String phone) {
    final message = 
      'EduConnect - Votre compte:\n'
      'Email: $email\n'
      'MDP: $password\n'
      'Téléchargez l\'app EduConnect.';

    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SMS copié. Collez dans votre application SMS.'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}