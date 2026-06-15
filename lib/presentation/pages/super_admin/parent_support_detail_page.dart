// lib/presentation/pages/super_admin/parent_support_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ParentSupportDetailPage extends StatefulWidget {
  final String parentId;

  const ParentSupportDetailPage({super.key, required this.parentId});

  @override
  State<ParentSupportDetailPage> createState() => _ParentSupportDetailPageState();
}

class _ParentSupportDetailPageState extends State<ParentSupportDetailPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _parentData;
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _adminLogs = [];
  final _noteController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Données parent complètes
      final parent = await _supabase
          .from('app_users')
          .select('''
            id, first_name, last_name, phone, email, created_at,
            parents(school_id),
            parent_subscriptions(*),
            parent_students(student_id, students(*, classes(name)))
          ''')
          .eq('id', widget.parentId)
          .single();

      // Paiements
      final payments = await _supabase
          .from('payment_transactions')
          .select('id, external_ref, amount, currency, status, created_at, screenshot_url, depositor_phone')
          .eq('parent_id', widget.parentId)
          .order('created_at', ascending: false);

      // Logs admin
      final logs = await _supabase
          .from('admin_actions_log')
          .select('action, details, reason, created_at, actor_id, app_users!admin_actions_log_actor_id_fkey(first_name, last_name)')
          .eq('target_user_id', widget.parentId)
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        _parentData = parent;
        _payments = List<Map<String, dynamic>>.from(payments);
        _adminLogs = List<Map<String, dynamic>>.from(logs);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_parentData == null) {
      return const Scaffold(
        body: Center(child: Text('Parent introuvable')),
      );
    }

    final user = _parentData!;
    final subscription = (user['parent_subscriptions'] as List?)?.isNotEmpty == true
        ? (user['parent_subscriptions'] as List).first as Map<String, dynamic>
        : null;
    final students = user['parent_students'] as List? ?? [];
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final phone = user['phone'] ?? '—';
    final createdAt = user['created_at'] != null ? DateTime.parse(user['created_at'].toString()) : null;

    // Statut abonnement
    final status = subscription?['status'] as String? ?? 'no_subscription';
    final daysRemaining = subscription?['days_remaining'] as int?;
    final isExpired = status == 'expired' || (daysRemaining != null && daysRemaining <= 0);
    final isExpiringSoon = !isExpired && daysRemaining != null && daysRemaining > 0 && daysRemaining <= 3;
    final isActive = !isExpired && !isExpiringSoon && (status == 'active' || status == 'trial');

    Color statusColor;
    String statusLabel;
    if (isExpired) {
      statusColor = Colors.red;
      statusLabel = 'Expiré${daysRemaining != null && daysRemaining < 0 ? ' depuis ${daysRemaining.abs()}j' : ''}';
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
      statusLabel = '$daysRemaining j restants';
    } else if (isActive) {
      statusColor = Colors.green;
      statusLabel = daysRemaining != null ? '$daysRemaining j restants' : 'Actif';
    } else {
      statusColor = Colors.blue;
      statusLabel = 'Essai gratuit';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Fiche Parent'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ HEADER PARENT
            _buildHeader(firstName, lastName, phone, createdAt),
            const SizedBox(height: 20),

            // ✅ CARTE ABONNEMENT + ACTIONS
            _buildSubscriptionCard(subscription, statusColor, statusLabel, status),
            const SizedBox(height: 20),

            // ✅ ENFANT(S)
            _buildChildrenSection(students),
            const SizedBox(height: 20),

            // ✅ HISTORIQUE PAIEMENTS
            _buildPaymentsSection(),
            const SizedBox(height: 20),

            // ✅ NOTES INTERNES
            _buildNotesSection(),
            const SizedBox(height: 20),

            // ✅ LOG ADMIN
            _buildAdminLogsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String firstName, String lastName, String phone, DateTime? createdAt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A44D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$firstName $lastName',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Inscrit le ${DateFormat('dd/MM/yyyy').format(createdAt)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white70),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📋 Téléphone copié')),
              );
            },
            tooltip: 'Copier le numéro',
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic>? sub, Color color, String label, String rawStatus) {
    final amount = sub?['amount'] ?? 1000;
    final currency = sub?['currency'] ?? 'XOF';
    final endDate = sub?['trial_ends_at'] != null
        ? DateTime.tryParse(sub?['trial_ends_at'])
        : (sub?['current_period_end'] != null ? DateTime.tryParse(sub?['current_period_end']) : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      rawStatus == 'expired' ? Icons.error_outline : rawStatus == 'trial' ? Icons.access_time : Icons.check_circle,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (endDate != null)
                Text(
                  'Fin: ${DateFormat('dd/MM/yyyy').format(endDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$amount $currency/mois',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 16),
          // ✅ ACTIONS RAPIDES
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildActionChip(
                icon: Icons.check_circle,
                label: 'Forcer actif',
                color: Colors.green,
                onTap: () => _showForceStatusDialog('active'),
              ),
              _buildActionChip(
                icon: Icons.card_giftcard,
                label: 'Forcer trial',
                color: Colors.blue,
                onTap: () => _showForceStatusDialog('trial'),
              ),
              _buildActionChip(
                icon: Icons.block,
                label: 'Forcer expiré',
                color: Colors.red,
                onTap: () => _showForceStatusDialog('expired'),
              ),
              _buildActionChip(
                icon: Icons.message,
                label: 'SMS',
                color: const Color(0xFF25D366),
                onTap: () => _showSmsDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenSection(List<dynamic> students) {
    if (students.isEmpty) {
      return _buildSectionCard(
        title: 'Enfant(s) lié(s)',
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aucun enfant lié. Contacter l\'administration.',
                  style: TextStyle(color: Colors.orange[800], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildSectionCard(
      title: 'Enfant(s) lié(s)',
      child: Column(
        children: students.map((s) {
          final student = s['students'] as Map?;
          final className = student?['classes']?['name'] ?? 'Classe inconnue';
          final matricule = student?['matricule'] ?? '—';
          final name = student != null ? '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}' : '—';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
              child: Text(
                name.isNotEmpty ? '${name[0]}' : '?',
                style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Matricule: $matricule • $className', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentsSection() {
    return _buildSectionCard(
      title: 'Historique des paiements (${_payments.length})',
      child: _payments.isEmpty
          ? Text('Aucun paiement', style: TextStyle(color: Colors.grey[600], fontSize: 13))
          : Column(
              children: _payments.map((p) {
                final status = p['status'] as String? ?? 'pending';
                final isValidated = status == 'validated';
                final date = p['created_at'] != null ? DateTime.parse(p['created_at'].toString()) : null;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isValidated ? Icons.check_circle : Icons.hourglass_top,
                    color: isValidated ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  title: Text(
                    '${p['amount'] ?? 0} ${p['currency'] ?? 'XOF'}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Réf: ${p['external_ref'] ?? '—'}${date != null ? ' • ${DateFormat('dd/MM/yy HH:mm').format(date)}' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isValidated ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        color: isValidated ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNotesSection() {
    return _buildSectionCard(
      title: 'Notes internes',
      child: Column(
        children: [
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ajouter une note...',
              filled: true,
              fillColor: Colors.yellow.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.yellow.withOpacity(0.3)),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF6C63FF)),
                onPressed: _addNote,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminLogsSection() {
    return _buildSectionCard(
      title: 'Log des actions (${_adminLogs.length})',
      child: _adminLogs.isEmpty
          ? Text('Aucune action', style: TextStyle(color: Colors.grey[600], fontSize: 13))
          : Column(
              children: _adminLogs.map((log) {
                final action = log['action'] as String? ?? '—';
                final date = log['created_at'] != null ? DateTime.parse(log['created_at'].toString()) : null;
                final actor = log['app_users'] as Map?;
                final actorName = actor != null ? '${actor['first_name'] ?? ''} ${actor['last_name'] ?? ''}' : 'Système';
                final reason = log['reason'] as String? ?? '';

                Color actionColor;
                if (action.contains('force')) actionColor = Colors.orange;
                else if (action.contains('send')) actionColor = Colors.blue;
                else if (action.contains('delete')) actionColor = Colors.red;
                else actionColor = Colors.grey;

                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: actionColor, shape: BoxShape.circle),
                  ),
                  title: Text(action, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: actionColor)),
                  subtitle: Text(
                    '$actorName${reason.isNotEmpty ? ' • $reason' : ''}${date != null ? ' • ${DateFormat('dd/MM HH:mm').format(date)}' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  void _showForceStatusDialog(String newStatus) {
    _reasonController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Forcer ${_statusLabel(newStatus)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Le statut de l\'abonnement sera changé en "$newStatus".'),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Motif (obligatoire, min 10 caractères)',
                hintText: 'Ex: Paiement reçu en espèce le 15/06',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_reasonController.text.trim().length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Motif trop court (min 10 caractères)')),
                );
                return;
              }
              Navigator.pop(context);
              await _forceStatus(newStatus, _reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return 'Actif';
      case 'trial': return 'Trial';
      case 'expired': return 'Expiré';
      default: return status;
    }
  }

  Future<void> _forceStatus(String newStatus, String reason) async {
    try {
      final result = await _supabase.rpc('force_subscription_status', params: {
        'p_parent_id': widget.parentId,
        'p_new_status': newStatus,
        'p_reason': reason,
        'p_actor_id': _supabase.auth.currentUser?.id,
      });

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Statut changé en ${_statusLabel(newStatus)}'), backgroundColor: Colors.green),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${result?['message'] ?? 'Erreur'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSmsDialog() {
    final message = 'Bonjour, votre abonnement EduConnect nécessite une action. Contactez le support au +225...';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Envoyer SMS'),
        content: TextField(
          controller: TextEditingController(text: message),
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📱 SMS envoyé (placeholder)')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;
    // TODO: Sauvegarder la note dans une table support_notes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📝 Note ajoutée')),
    );
    _noteController.clear();
  }
}
