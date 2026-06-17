// lib/presentation/pages/super_admin/support_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'parent_support_detail_page.dart';

class SupportDashboardPage extends StatefulWidget {
  const SupportDashboardPage({super.key});

  @override
  State<SupportDashboardPage> createState() => _SupportDashboardPageState();
}

class _SupportDashboardPageState extends State<SupportDashboardPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedParents = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  int _tmrMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // ========== ÉTAPE 1 : Parents (100 derniers) ==========
      final parentsResult = await _supabase
          .from('app_users')
          .select('id, first_name, last_name, phone, school_id, created_at')
          .eq('role', 'parent')
          .order('created_at', ascending: false)
          .limit(100);

      final parentsList = List<Map<String, dynamic>>.from(parentsResult);
      final parentIds = parentsList.map((p) => p['id'] as String).toList();
      final schoolIds = parentsList
          .where((p) => p['school_id'] != null)
          .map((p) => p['school_id'] as String)
          .toSet()
          .toList();

      // Map rapide id -> parent pour les paiements
      final parentsById = {for (var p in parentsList) p['id'] as String: p};

      // ========== ÉTAPE 2 : Subscriptions (toutes, filtrées côté Dart) ==========
      final Map<String, Map<String, dynamic>> subsByParent = {};
      if (parentIds.isNotEmpty) {
        final subsResult = await _supabase
            .from('parent_subscriptions')
            .select('parent_id, status, plan_type, trial_ends_at, current_period_end, amount, currency')
            .limit(1000);

        for (final s in List<Map<String, dynamic>>.from(subsResult)) {
          final pid = s['parent_id'] as String?;
          if (pid != null && parentIds.contains(pid)) {
            subsByParent[pid] = s;
          }
        }
      }

      // ========== ÉTAPE 3 : Schools (toutes, filtrées côté Dart) ==========
      final Map<String, Map<String, dynamic>> schoolsById = {};
      if (schoolIds.isNotEmpty) {
        final schoolsResult = await _supabase
            .from('schools')
            .select('id, name')
            .limit(1000);

        for (final s in List<Map<String, dynamic>>.from(schoolsResult)) {
          final sid = s['id'] as String?;
          if (sid != null && schoolIds.contains(sid)) {
            schoolsById[sid] = s;
          }
        }
      }

      // ========== Assembler parents + subs + schools ==========
      final rawList = parentsList.map((p) {
        final sub = subsByParent[p['id']];
        final school = schoolsById[p['school_id']];
        return {
          ...p,
          'parent_subscriptions': sub != null ? [sub] : <Map<String, dynamic>>[],
          'schools': school,
        };
      }).toList();

      // ========== ÉTAPE 4 : Paiements en attente ==========
      final pendingPaymentsResult = await _supabase
          .from('payment_transactions')
          .select('id, parent_id, amount, currency, status, external_ref, created_at, screenshot_url, depositor_phone')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(50);

      final pendingRaw = List<Map<String, dynamic>>.from(pendingPaymentsResult);

      // ========== ÉTAPE 5 : Noms des parents pour les paiements ==========
      // Identifier les parents manquants dans parentsById
      final Set<String> neededParentIds = pendingRaw
          .map((p) => p['parent_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();
      
      final missingParentIds = neededParentIds.difference(parentsById.keys.toSet()).toList();
      
      // Charger les parents manquants (tous les parents, filtrés côté Dart)
      final Map<String, Map<String, dynamic>> extraParents = {};
      if (missingParentIds.isNotEmpty) {
        final allParentsResult = await _supabase
            .from('app_users')
            .select('id, first_name, last_name, phone')
            .eq('role', 'parent')
            .limit(1000);
        
        for (final p in List<Map<String, dynamic>>.from(allParentsResult)) {
          final id = p['id'] as String?;
          if (id != null && missingParentIds.contains(id)) {
            extraParents[id] = p;
          }
        }
      }
      
      // Fusionner avec les parents déjà chargés
      final allParentsForPayments = {...parentsById, ...extraParents};

      final pending = pendingRaw.map((p) {
        final parentId = p['parent_id'] as String?;
        final parent = allParentsForPayments[parentId];
        return {
          'id': p['id'],
          'parent_id': parentId,
          'parent_name': parent != null
              ? '${parent['first_name'] ?? ''} ${parent['last_name'] ?? ''}'
              : '—',
          'phone': parent?['phone'],
          'amount': p['amount'],
          'currency': p['currency'],
          'external_ref': p['external_ref'],
          'status': p['status'],
          'created_at': p['created_at'],
          'screenshot_url': p['screenshot_url'],
          'depositor_phone': p['depositor_phone'],
        };
      }).toList();

      // ========== Filtrer SEULEMENT les vrais bloqués ==========
      final blocked = rawList.where((p) {
        final subs = p['parent_subscriptions'] as List?;
        if (subs == null || subs.isEmpty) return true;

        final sub = subs.first as Map<String, dynamic>;
        final status = sub['status'] as String?;
        final planType = sub['plan_type'] as String?;
        final trialEnd = sub['trial_ends_at'] != null
            ? DateTime.tryParse(sub['trial_ends_at'].toString())
            : null;
        final periodEnd = sub['current_period_end'] != null
            ? DateTime.tryParse(sub['current_period_end'].toString())
            : null;

        if (status == 'expired') return true;
        if (status == 'pending') return true;
        if (status == null) return true;

        if (planType == 'trial' && trialEnd != null && trialEnd.isBefore(DateTime.now())) return true;
        if (planType == 'monthly' && periodEnd != null && periodEnd.isBefore(DateTime.now())) return true;

        if (status == 'active') {
          if (planType == 'trial' && trialEnd != null && trialEnd.isAfter(DateTime.now())) return false;
          if (planType == 'monthly' && periodEnd != null && periodEnd.isAfter(DateTime.now())) return false;
        }
        return true;
      }).map((p) {
        final subs = p['parent_subscriptions'] as List?;
        final sub = subs != null && subs.isNotEmpty ? subs.first as Map<String, dynamic> : null;
        final school = p['schools'] as Map<String, dynamic>?;

        int? daysRemaining;
        if (sub != null) {
          final planType = sub['plan_type'] as String?;
          final trialEnd = sub['trial_ends_at'] != null
              ? DateTime.tryParse(sub['trial_ends_at'].toString())
              : null;
          final periodEnd = sub['current_period_end'] != null
              ? DateTime.tryParse(sub['current_period_end'].toString())
              : null;

          if (planType == 'trial' && trialEnd != null) {
            daysRemaining = trialEnd.difference(DateTime.now()).inDays;
            if (daysRemaining < 0) daysRemaining = 0;
          } else if (planType == 'monthly' && periodEnd != null) {
            daysRemaining = periodEnd.difference(DateTime.now()).inDays;
            if (daysRemaining < 0) daysRemaining = 0;
          }
        }

        return {
          'parent_id': p['id'],
          'first_name': p['first_name'],
          'last_name': p['last_name'],
          'phone': p['phone'],
          'school_name': school?['name'],
          'status': sub?['status'],
          'plan_type': sub?['plan_type'],
          'days_remaining': daysRemaining,
          'trial_ends_at': sub?['trial_ends_at'],
          'current_period_end': sub?['current_period_end'],
          'amount': sub?['amount'],
          'currency': sub?['currency'],
        };
      }).toList();

      setState(() {
        _blockedParents = blocked;
        _pendingPayments = pending;
        _tmrMinutes = 12;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Support Client'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiRow(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Parents bloqués (${_blockedParents.length})', Colors.red),
                    const SizedBox(height: 12),
                    _blockedParents.isEmpty
                        ? _buildEmptyState('Aucun parent bloqué', Icons.check_circle, Colors.green)
                        : _buildBlockedParentsList(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Paiements en attente (${_pendingPayments.length})', Colors.orange),
                    const SizedBox(height: 12),
                    _pendingPayments.isEmpty
                        ? _buildEmptyState('Aucun paiement en attente', Icons.check_circle, Colors.green)
                        : _buildPendingPaymentsList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKpiRow() {
    return Row(
      children: [
        Expanded(child: _buildKpiCard('Tickets', '${_blockedParents.length}', Icons.support_agent, const Color(0xFF6C63FF))),
        const SizedBox(width: 12),
        Expanded(child: _buildKpiCard('TMR', '$_tmrMinutes min', Icons.timer, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildKpiCard('Bloqués', '${_blockedParents.length}', Icons.block, Colors.red)),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildEmptyState(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBlockedParentsList() {
    return Column(
      children: _blockedParents.map((p) {
        final days = p['days_remaining'] as int?;
        final status = p['status'] as String?;
        final planType = p['plan_type'] as String?;

        final bool isExpired = status == 'expired' || (days != null && days <= 0);
        final bool isNoSub = status == null;
        final bool isTrialExpired = planType == 'trial' && (days == null || days <= 0);
        final bool isPending = status == 'pending';

        final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}';
        final phone = p['phone'] ?? '—';
        final school = p['school_name'] ?? '—';

        String subtitleText;
        Color statusColor;
        IconData statusIcon;

        if (isNoSub) {
          statusColor = Colors.red;
          statusIcon = Icons.block;
          subtitleText = 'Aucun abonnement';
        } else if (isExpired) {
          statusColor = Colors.red;
          statusIcon = Icons.block;
          subtitleText = days != null && days < 0
              ? 'Expiré depuis ${days.abs()} jours'
              : 'Abonnement expiré';
        } else if (isTrialExpired) {
          statusColor = Colors.orange;
          statusIcon = Icons.access_time;
          subtitleText = 'Essai terminé';
        } else if (isPending) {
          statusColor = Colors.orange;
          statusIcon = Icons.hourglass_top;
          subtitleText = 'En attente de validation';
        } else {
          statusColor = Colors.grey;
          statusIcon = Icons.help;
          subtitleText = 'Statut: $status';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: Icon(statusIcon, color: Colors.white, size: 18),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$phone • $school', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                  subtitleText,
                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6C63FF)),
            onTap: () => _openParentDetail(p['parent_id']?.toString() ?? ''),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPendingPaymentsList() {
    return Column(
      children: _pendingPayments.map((p) {
        final name = p['parent_name'] ?? '—';
        final ref = p['external_ref'] ?? '—';
        final amount = p['amount'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.15),
              child: const Icon(Icons.hourglass_top, color: Colors.orange, size: 18),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Réf: $ref • $amount XOF', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                  onPressed: () => _validatePayment(p['id'].toString()),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
                  onPressed: () => _rejectPayment(p['id'].toString()),
                ),
              ],
            ),
            onTap: () => _openParentDetail(p['parent_id']?.toString() ?? ''),
          ),
        );
      }).toList(),
    );
  }

  void _openParentDetail(String parentId) {
    if (parentId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ParentSupportDetailPage(parentId: parentId)),
    );
  }

  Future<void> _validatePayment(String paymentId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paiement validé ✅'), backgroundColor: Colors.green),
    );
    _loadData();
  }

  Future<void> _rejectPayment(String paymentId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paiement rejeté ❌'), backgroundColor: Colors.red),
    );
    _loadData();
  }
}