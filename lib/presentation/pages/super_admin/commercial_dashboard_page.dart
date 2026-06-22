// lib/presentation/pages/super_admin/commercial_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CommercialDashboardPage extends StatefulWidget {
  final String? countryCode;

  const CommercialDashboardPage({super.key, this.countryCode});

  @override
  State<CommercialDashboardPage> createState() => _CommercialDashboardPageState();
}

class _CommercialDashboardPageState extends State<CommercialDashboardPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _schools = [];
  
  String _parentFilter = 'all';
  String _schoolFilter = 'all';

  // ✅ AJOUTÉ : Vérifie si on filtre par pays
  bool get _hasCountryFilter => widget.countryCode != null && widget.countryCode!.isNotEmpty;

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
          .select('id, first_name, last_name, phone, school_id, country_code, created_at')
          .eq('role', 'parent');

      if (_hasCountryFilter) {
        parentsQuery = parentsQuery.eq('country_code', widget.countryCode!);
      }

      final parentsResult = await parentsQuery
          .order('created_at', ascending: false)
          .limit(200);

      var parentsList = List<Map<String, dynamic>>.from(parentsResult);
      final parentIds = parentsList.map((p) => p['id'] as String).toList();

      // ========== ÉTAPE 2 : Subscriptions ==========
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

      // ========== ÉTAPE 3 : Écoles ==========
      final Map<String, Map<String, dynamic>> schoolsById = {};
      final Map<String, List<Map<String, dynamic>>> parentsBySchool = {};
      
      var schoolsQuery = _supabase
          .from('schools')
          .select('id, name, phone, created_at, is_test, country_code');

      if (_hasCountryFilter) {
        schoolsQuery = schoolsQuery.eq('country_code', widget.countryCode!);
      }

      final allSchoolsResult = await schoolsQuery
          .order('created_at', ascending: false)
          .limit(200);

      var allSchoolsList = List<Map<String, dynamic>>.from(allSchoolsResult);

      for (final s in allSchoolsList) {
        final sid = s['id'] as String?;
        if (sid != null) schoolsById[sid] = s;
      }

      // ========== Assembler parents ==========
      final now = DateTime.now();
      final parents = parentsList.map((p) {
        final sub = subsByParent[p['id']];
        final school = schoolsById[p['school_id']];
        
        String commercialStatus = 'no_subscription';
        String? subStatus = sub?['status'] as String?;
        String? planType = sub?['plan_type'] as String?;
        DateTime? trialEnd = sub?['trial_ends_at'] != null 
            ? DateTime.tryParse(sub!['trial_ends_at'].toString()) 
            : null;
        DateTime? periodEnd = sub?['current_period_end'] != null 
            ? DateTime.tryParse(sub!['current_period_end'].toString()) 
            : null;

        if (sub == null) {
          commercialStatus = 'no_subscription';
        } else if (subStatus == 'active' && planType == 'monthly' && periodEnd != null && periodEnd.isAfter(now)) {
          commercialStatus = 'paying';
        } else if (subStatus == 'active' && planType == 'trial' && trialEnd != null && trialEnd.isAfter(now)) {
          commercialStatus = 'trial_active';
        } else if (planType == 'trial' && trialEnd != null && trialEnd.isBefore(now)) {
          commercialStatus = 'trial_expired';
        } else if (subStatus == 'expired' || subStatus == 'pending') {
          commercialStatus = subStatus!;
        } else {
          commercialStatus = 'no_subscription';
        }

        final createdAt = p['created_at'] != null 
            ? DateTime.tryParse(p['created_at'].toString()) 
            : null;
        final daysSinceCreated = createdAt != null ? now.difference(createdAt).inDays : 0;

        return {
          'id': p['id'],
          'name': '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim(),
          'phone': p['phone'] ?? '—',
          'school_name': school?['name'] ?? '—',
          'school_id': p['school_id'],
          'created_at': createdAt,
          'days_since_created': daysSinceCreated,
          'commercial_status': commercialStatus,
          'subscription_status': subStatus,
          'plan_type': planType,
          'trial_ends_at': trialEnd,
          'current_period_end': periodEnd,
          'amount': sub?['amount'],
          'currency': sub?['currency'],
        };
      }).toList();

      for (final p in parents) {
        final sid = p['school_id'] as String?;
        if (sid != null) {
          parentsBySchool.putIfAbsent(sid, () => []);
          parentsBySchool[sid]!.add(p);
        }
      }

      final schools = allSchoolsList.map((s) {
        final sid = s['id'] as String;
        final schoolParents = parentsBySchool[sid] ?? [];
        final payingCount = schoolParents.where((p) => p['commercial_status'] == 'paying').length;
        final trialActiveCount = schoolParents.where((p) => p['commercial_status'] == 'trial_active').length;
        final trialExpiredCount = schoolParents.where((p) => p['commercial_status'] == 'trial_expired').length;
        final noSubCount = schoolParents.where((p) => p['commercial_status'] == 'no_subscription').length;
        
        String schoolStatus = 'prospect';
        if (payingCount > 0) {
          schoolStatus = 'paying';
        } else if (trialActiveCount > 0 || trialExpiredCount > 0) {
          schoolStatus = 'trial';
        } else if (noSubCount > 0) {
          schoolStatus = 'contacted';
        }

        return {
          'id': sid,
          'name': s['name'] ?? '—',
          'phone': s['phone'] ?? '—',
          'created_at': s['created_at'] != null ? DateTime.tryParse(s['created_at'].toString()) : null,
          'is_test': s['is_test'] == true,
          'total_parents': schoolParents.length,
          'paying_count': payingCount,
          'trial_active_count': trialActiveCount,
          'trial_expired_count': trialExpiredCount,
          'no_sub_count': noSubCount,
          'school_status': schoolStatus,
        };
      }).toList();

      setState(() {
        _parents = parents;
        _schools = schools;
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

  List<Map<String, dynamic>> get _filteredParents {
    switch (_parentFilter) {
      case 'no_sub':
        return _parents.where((p) => p['commercial_status'] == 'no_subscription').toList();
      case 'trial_expired':
        return _parents.where((p) => p['commercial_status'] == 'trial_expired').toList();
      case 'to_call':
        return _parents.where((p) {
          final status = p['commercial_status'] as String;
          return status == 'no_subscription' || status == 'trial_expired' || status == 'expired';
        }).toList();
      default:
        return _parents;
    }
  }

  List<Map<String, dynamic>> get _filteredSchools {
    switch (_schoolFilter) {
      case 'prospect':
        return _schools.where((s) => s['school_status'] == 'prospect').toList();
      case 'trial':
        return _schools.where((s) => s['school_status'] == 'trial').toList();
      case 'paying':
        return _schools.where((s) => s['school_status'] == 'paying').toList();
      default:
        return _schools;
    }
  }

  @override
  Widget build(BuildContext context) {
    final noSubCount = _parents.where((p) => p['commercial_status'] == 'no_subscription').length;
    final trialExpiredCount = _parents.where((p) => p['commercial_status'] == 'trial_expired').length;
    final payingCount = _parents.where((p) => p['commercial_status'] == 'paying').length;
    final trialSchools = _schools.where((s) => s['school_status'] == 'trial').length;
    final payingSchools = _schools.where((s) => s['school_status'] == 'paying').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Commercial',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiRow(noSubCount, trialExpiredCount, payingCount, payingSchools),
                    const SizedBox(height: 20),
                    
                    _buildSectionHeader('Parents', noSubCount, trialExpiredCount, payingCount),
                    const SizedBox(height: 10),
                    _buildParentFilters(),
                    const SizedBox(height: 10),
                    _filteredParents.isEmpty
                        ? _buildEmptyState('Aucun parent dans cette catégorie')
                        : _buildParentsList(),
                    
                    const SizedBox(height: 28),
                    
                    _buildSectionTitle('Écoles', Colors.blue),
                    const SizedBox(height: 10),
                    _buildSchoolFilters(trialSchools, payingSchools),
                    const SizedBox(height: 10),
                    _filteredSchools.isEmpty
                        ? _buildEmptyState('Aucune école dans cette catégorie')
                        : _buildSchoolsList(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKpiRow(int noSub, int trialExpired, int payingParents, int payingSchools) {
    return Row(
      children: [
        Expanded(child: _buildKpiCard('Prospects', '$noSub', Icons.person_outline, Colors.orange)),
        const SizedBox(width: 6),
        Expanded(child: _buildKpiCard('Essais finis', '$trialExpired', Icons.timer_off, Colors.red)),
        const SizedBox(width: 6),
        Expanded(child: _buildKpiCard('Payants', '$payingParents', Icons.payment, Colors.green)),
        const SizedBox(width: 6),
        Expanded(child: _buildKpiCard('Écoles', '$payingSchools', Icons.school, const Color(0xFF6C63FF))),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int noSub, int trialExp, int paying) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$noSub sans abo • $trialExp essai fini • $paying payant',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildParentFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Tous', 'all', _parentFilter, (v) => setState(() => _parentFilter = v)),
          const SizedBox(width: 6),
          _buildFilterChip('Sans abo', 'no_sub', _parentFilter, (v) => setState(() => _parentFilter = v)),
          const SizedBox(width: 6),
          _buildFilterChip('Essai fini', 'trial_expired', _parentFilter, (v) => setState(() => _parentFilter = v)),
          const SizedBox(width: 6),
          _buildFilterChip('À relancer', 'to_call', _parentFilter, (v) => setState(() => _parentFilter = v)),
        ],
      ),
    );
  }

  Widget _buildSchoolFilters(int trialSchools, int payingSchools) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Toutes', 'all', _schoolFilter, (v) => setState(() => _schoolFilter = v)),
          const SizedBox(width: 6),
          _buildFilterChip('Prospects', 'prospect', _schoolFilter, (v) => setState(() => _schoolFilter = v)),
          const SizedBox(width: 6),
          _buildFilterChip('Essai ($trialSchools)', 'trial', _schoolFilter, (v) => setState(() => _schoolFilter = v)),
          const SizedBox(width: 6),
          _buildFilterChip('Payant ($payingSchools)', 'paying', _schoolFilter, (v) => setState(() => _schoolFilter = v)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String groupValue, Function(String) onSelected) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: const Color(0xFF6C63FF),
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ✅ CORRIGÉ : Expanded + maxLines pour éviter overflow
  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentsList() {
    return Column(
      children: _filteredParents.map((p) {
        final name = p['name'] as String;
        final phone = p['phone'] as String;
        final school = p['school_name'] as String;
        final days = p['days_since_created'] as int;
        final status = p['commercial_status'] as String;
        
        Color statusColor;
        String statusLabel;
        IconData statusIcon;
        
        switch (status) {
          case 'no_subscription':
            statusColor = Colors.orange;
            statusLabel = 'Jamais abonné';
            statusIcon = Icons.person_outline;
            break;
          case 'trial_expired':
            statusColor = Colors.red;
            statusLabel = 'Essai terminé';
            statusIcon = Icons.timer_off;
            break;
          case 'expired':
            statusColor = Colors.red;
            statusLabel = 'Abonnement expiré';
            statusIcon = Icons.block;
            break;
          case 'paying':
            statusColor = Colors.green;
            statusLabel = 'Payant';
            statusIcon = Icons.payment;
            break;
          case 'trial_active':
            statusColor = Colors.blue;
            statusLabel = 'En essai';
            statusIcon = Icons.access_time;
            break;
          default:
            statusColor = Colors.grey;
            statusLabel = status;
            statusIcon = Icons.help;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.15),
                      child: Icon(statusIcon, color: statusColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$school • $phone',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Créé il y a $days jours',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.message,
                      label: 'SMS',
                      color: const Color(0xFF25D366),
                      onTap: () => _copyAndSms(phone, name),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.phone,
                      label: 'Appeler',
                      color: Colors.blue,
                      onTap: () => _copyPhone(phone),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Contacté',
                      color: Colors.grey[600]!,
                      onTap: () => _markContacted(name),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSchoolsList() {
    return Column(
      children: _filteredSchools.map((s) {
        final name = s['name'] as String;
        final total = s['total_parents'] as int;
        final paying = s['paying_count'] as int;
        final trialActive = s['trial_active_count'] as int;
        final trialExpired = s['trial_expired_count'] as int;
        final status = s['school_status'] as String;
        final isTest = s['is_test'] as bool;

        Color statusColor;
        String statusLabel;
        if (status == 'paying') {
          statusColor = Colors.green;
          statusLabel = 'Payante';
        } else if (status == 'trial') {
          statusColor = Colors.blue;
          statusLabel = 'En essai';
        } else if (status == 'contacted') {
          statusColor = Colors.orange;
          statusLabel = 'Contactée';
        } else {
          statusColor = Colors.grey;
          statusLabel = 'Prospect';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isTest ? BorderSide(color: Colors.orange.withOpacity(0.5), width: 2) : BorderSide.none,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.15),
              child: Icon(Icons.school, color: statusColor, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isTest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Text('TEST', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$total parent${total > 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (paying > 0) _buildMiniBadge('$paying payant', Colors.green),
                    if (trialActive > 0) _buildMiniBadge('$trialActive essai', Colors.blue),
                    if (trialExpired > 0) _buildMiniBadge('$trialExpired fini', Colors.red),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📋 $phone copié'), behavior: SnackBarBehavior.floating),
    );
  }

  void _copyAndSms(String phone, String name) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 $phone copié'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _markContacted(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $name marqué comme contacté'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}