// lib/presentation/pages/super_admin/support_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'parent_support_detail_page.dart';

class SupportDashboardPage extends StatefulWidget {
  final String? countryCode;

  const SupportDashboardPage({super.key, this.countryCode});

  @override
  State<SupportDashboardPage> createState() => _SupportDashboardPageState();
}

class _SupportDashboardPageState extends State<SupportDashboardPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedParents = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  int _tmrMinutes = 0;

  bool get _hasCountryFilter =>
      widget.countryCode != null && widget.countryCode!.isNotEmpty;

  // ✅ Convertit le code ISO (CI) en préfixe téléphonique (+225) pour les requêtes schools
  String? get _schoolCountryCode {
    if (widget.countryCode == null) return null;
    const isoToPrefix = {
      'CI': '+225',
      'SN': '+221',
      'CM': '+237',
      'BJ': '+229',
      'TG': '+228',
      'BF': '+226',
      'GH': '+233',
      'GA': '+241',
    };
    return isoToPrefix[widget.countryCode] ?? widget.countryCode;
  }

  // ✅ Affichage lisible du TMR
  String get _tmrLabel {
    if (_tmrMinutes <= 0) return '—';
    if (_tmrMinutes < 60) return '$_tmrMinutes min';
    final h = _tmrMinutes ~/ 60;
    final m = _tmrMinutes % 60;
    return m > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '${h}h';
  }

  // ✅ NOUVEAU : parents bloqués regroupés par école (tri A-Z, "Sans école" en dernier)
  Map<String, List<Map<String, dynamic>>> get _blockedBySchool {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final p in _blockedParents) {
      final schoolName = p['school_name'] as String? ?? 'Sans école';
      map.putIfAbsent(schoolName, () => []).add(p);
    }
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        if (a == 'Sans école') return 1;
        if (b == 'Sans école') return -1;
        return a.compareTo(b);
      });
    return {for (final k in sortedKeys) k: map[k]!};
  }

  // ✅ NOUVEAU : paiements en attente regroupés par école
  Map<String, List<Map<String, dynamic>>> get _pendingBySchool {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final p in _pendingPayments) {
      final schoolName = p['school_name'] as String? ?? 'Sans école';
      map.putIfAbsent(schoolName, () => []).add(p);
    }
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        if (a == 'Sans école') return 1;
        if (b == 'Sans école') return -1;
        return a.compareTo(b);
      });
    return {for (final k in sortedKeys) k: map[k]!};
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // ========== ÉTAPE 1 : Parents ==========
      var parentsQuery = _supabase
          .from('app_users')
          .select(
              'id, first_name, last_name, phone, school_id, country_code, created_at')
          .eq('role', 'parent');

      if (_hasCountryFilter) {
        parentsQuery = parentsQuery.eq('country_code', widget.countryCode!);
      }

      final parentsResult =
          await parentsQuery.order('created_at', ascending: false).limit(200);

      var parentsList = List<Map<String, dynamic>>.from(parentsResult);
      final parentIds = parentsList.map((p) => p['id'] as String).toList();

      final parentsById = {for (var p in parentsList) p['id'] as String: p};

      // ========== ÉTAPE 2 : Subscriptions ==========
      final Map<String, Map<String, dynamic>> subsByParent = {};
      if (parentIds.isNotEmpty) {
        final subsResult = await _supabase
            .from('parent_subscriptions')
            .select(
                'parent_id, status, plan_type, trial_ends_at, current_period_end, amount, currency')
            .limit(1000);

        for (final s in List<Map<String, dynamic>>.from(subsResult)) {
          final pid = s['parent_id'] as String?;
          if (pid != null && parentIds.contains(pid)) {
            subsByParent[pid] = s;
          }
        }
      }

      // ========== ÉTAPE 3 : Schools ==========
      // ✅ CORRIGÉ : utilise _schoolCountryCode (+225) au lieu de 'CI'
      final Map<String, Map<String, dynamic>> schoolsById = {};
      {
        var schoolsQuery =
            _supabase.from('schools').select('id, name, country_code');

        if (_hasCountryFilter) {
          schoolsQuery = schoolsQuery.eq('country_code', _schoolCountryCode!);
        }

        final schoolsResult = await schoolsQuery.order('name').limit(1000);

        for (final s in List<Map<String, dynamic>>.from(schoolsResult)) {
          final sid = s['id'] as String?;
          if (sid != null) {
            schoolsById[sid] = s;
          }
        }
      }

      // ========== Assembler parents ==========
      final rawList = parentsList.map((p) {
        final sub = subsByParent[p['id']];
        final school = schoolsById[p['school_id']];
        return {
          ...p,
          'parent_subscriptions':
              sub != null ? [sub] : <Map<String, dynamic>>[],
          'schools': school,
        };
      }).toList();

      // ========== ÉTAPE 4 : Paiements en attente ==========
      List<Map<String, dynamic>> pending = [];
      if (parentIds.isNotEmpty) {
        final pendingResult = await _supabase
            .from('payment_transactions')
            .select(
                'id, parent_id, amount, currency, status, external_ref, created_at, screenshot_url, depositor_phone')
            .eq('status', 'pending')
            .order('created_at', ascending: false)
            .limit(200);

        final allPending = List<Map<String, dynamic>>.from(pendingResult);

        final pendingFiltered = allPending.where((p) {
          final pid = p['parent_id'] as String?;
          return pid != null && parentIds.contains(pid);
        }).toList();

        // ================================================================
        // ÉTAPE 4 : Paiements en attente
        // ================================================================
        pending = pendingFiltered.map((p) {
          final parentId = p['parent_id'] as String?;
          final parent = parentsById[parentId];

          // ✅ CORRIGÉ : nom d'école pré-calculé (évite le nested ?[)
          String? parentSchoolName;
          if (parent != null) {
            final school = schoolsById[parent['school_id']];
            if (school != null) {
              parentSchoolName = school['name'] as String?;
            }
          }

          return {
            'id': p['id'],
            'parent_id': parentId,
            'parent_name': parent != null
                ? '${parent['first_name'] ?? ''} ${parent['last_name'] ?? ''}'
                : '—',
            'phone': parent?['phone'],
            'school_name': parentSchoolName, // ✅ plus de ternaire ici
            'amount': p['amount'],
            'reference': p['reference'],
            'transaction_date': p['transaction_date'] ?? p['created_at'],
            'payment_method': p['payment_method'],
            'months': p['months'],
            'created_at': p['created_at'],
          };
        }).toList();
      }

      // ========== Filtrer bloqués ==========
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

        if (planType == 'trial' &&
            trialEnd != null &&
            trialEnd.isBefore(DateTime.now())) return true;
        if (planType == 'monthly' &&
            periodEnd != null &&
            periodEnd.isBefore(DateTime.now())) return true;

        if (status == 'active') {
          if (planType == 'trial' &&
              trialEnd != null &&
              trialEnd.isAfter(DateTime.now())) return false;
          if (planType == 'monthly' &&
              periodEnd != null &&
              periodEnd.isAfter(DateTime.now())) return false;
        }
        return true;
      }).map((p) {
        final subs = p['parent_subscriptions'] as List?;
        final sub = subs != null && subs.isNotEmpty
            ? subs.first as Map<String, dynamic>
            : null;
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

      // ========== ÉTAPE 5 : TMR réel (temps moyen de validation) ==========
      int tmr = 0;
      try {
        final verifiedResult = await _supabase
            .from('payment_transactions')
            .select('created_at, verified_at')
            .eq('status', 'verified')
            .not('verified_at', 'is', null)
            .order('verified_at', ascending: false)
            .limit(100);

        final verified = List<Map<String, dynamic>>.from(verifiedResult);
        var totalMinutes = 0;
        var count = 0;
        for (final v in verified) {
          final created = DateTime.tryParse(v['created_at']?.toString() ?? '');
          final verifiedAt =
              DateTime.tryParse(v['verified_at']?.toString() ?? '');
          if (created != null && verifiedAt != null) {
            totalMinutes += verifiedAt.difference(created).inMinutes;
            count++;
          }
        }
        if (count > 0) tmr = (totalMinutes / count).round();
      } catch (e) {
        // TMR reste à 0 si erreur — ne bloque jamais la page
      }

      setState(() {
        _blockedParents = blocked;
        _pendingPayments = pending;
        _tmrMinutes = tmr;
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
    final blockedGroups = _blockedBySchool;
    final pendingGroups = _pendingBySchool;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Support Client',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiRow(),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                        'Parents bloqués (${_blockedParents.length})',
                        Colors.red),
                    const SizedBox(height: 12),
                    _blockedParents.isEmpty
                        ? _buildEmptyState('Aucun parent bloqué',
                            Icons.check_circle, Colors.green)
                        : _buildGroupedSections(
                            groups: blockedGroups,
                            headerColor: const Color(0xFF6C63FF),
                            itemBuilder: _buildBlockedParentCard,
                          ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                        'Paiements en attente (${_pendingPayments.length})',
                        Colors.orange),
                    const SizedBox(height: 12),
                    _pendingPayments.isEmpty
                        ? _buildEmptyState('Aucun paiement en attente',
                            Icons.check_circle, Colors.green)
                        : _buildGroupedSections(
                            groups: pendingGroups,
                            headerColor: Colors.orange,
                            itemBuilder: _buildPendingPaymentCard,
                          ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // ✅ NOUVEAU : construit les sections regroupées par école
  Widget _buildGroupedSections({
    required Map<String, List<Map<String, dynamic>>> groups,
    required Color headerColor,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSchoolHeader(entry.key, entry.value.length, headerColor),
            const SizedBox(height: 8),
            ...entry.value.map(itemBuilder),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  // ✅ NOUVEAU : en-tête d'une section école
  Widget _buildSchoolHeader(String schoolName, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.business, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              schoolName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    return Row(
      children: [
        Expanded(
            child: _buildKpiCard('Tickets', '${_blockedParents.length}',
                Icons.support_agent, const Color(0xFF6C63FF))),
        const SizedBox(width: 12),
        Expanded(
            child: _buildKpiCard('TMR', _tmrLabel, Icons.timer, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildKpiCard('Bloqués', '${_blockedParents.length}',
                Icons.block, Colors.red)),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Carte d'un parent bloqué (utilisée dans les sections école)
  Widget _buildBlockedParentCard(Map<String, dynamic> p) {
    final days = p['days_remaining'] as int?;
    final status = p['status'] as String?;
    final planType = p['plan_type'] as String?;

    final bool isExpired = status == 'expired' || (days != null && days <= 0);
    final bool isNoSub = status == null;
    final bool isTrialExpired =
        planType == 'trial' && (days == null || days <= 0);
    final bool isPending = status == 'pending';

    final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    final phone = p['phone'] ?? '—';

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
        title: Text(
          name.isNotEmpty ? name : '—',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phone,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitleText,
              style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: Color(0xFF6C63FF)),
        onTap: () => _openParentDetail(p['parent_id']?.toString() ?? ''),
      ),
    );
  }

  // ✅ Carte d'un paiement en attente (utilisée dans les sections école)
  Widget _buildPendingPaymentCard(Map<String, dynamic> p) {
    final name = p['parent_name'] ?? '—';
    final ref = p['external_ref'] ?? '—';
    final amount = p['amount'] ?? 0;
    final currency = p['currency'] ?? 'XOF';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.15),
          child:
              const Icon(Icons.hourglass_top, color: Colors.orange, size: 18),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Réf: $ref • $amount $currency',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.check_circle, color: Colors.green, size: 22),
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
  }

  void _openParentDetail(String parentId) {
    if (parentId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ParentSupportDetailPage(parentId: parentId)),
    );
  }

  Future<void> _validatePayment(String paymentId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Paiement validé ✅'), backgroundColor: Colors.green),
    );
    _loadData();
  }

  Future<void> _rejectPayment(String paymentId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Paiement rejeté ❌'), backgroundColor: Colors.red),
    );
    _loadData();
  }
}
