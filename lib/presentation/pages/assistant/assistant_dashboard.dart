// lib/presentation/pages/assistant/assistant_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../blocs/auth_bloc/auth_bloc.dart' as auth;
import '../super_admin/support_dashboard_page.dart';
import '../super_admin/commercial_dashboard_page.dart';
import '../super_admin/subscriptions/subscription_dashboard_page.dart';

class AssistantDashboard extends StatefulWidget {
  final String countryCode;

  const AssistantDashboard({
    super.key,
    required this.countryCode,
  });

  @override
  State<AssistantDashboard> createState() => _AssistantDashboardState();
}

class _AssistantDashboardState extends State<AssistantDashboard> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  int _blockedCount = 0;
  int _pendingPaymentsCount = 0;
  int _schoolsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final parentsResult = await _supabase
          .from('app_users')
          .select('id')
          .eq('role', 'parent')
          .eq('country_code', widget.countryCode);

      final parentIds = List<Map<String, dynamic>>.from(parentsResult)
          .map((p) => p['id'] as String)
          .toList();

      int blocked = 0;
      if (parentIds.isNotEmpty) {
        final subsResult = await _supabase
            .from('parent_subscriptions')
            .select('parent_id, status, trial_ends_at, current_period_end, plan_type')
            .limit(1000);

        final now = DateTime.now();
        for (final s in List<Map<String, dynamic>>.from(subsResult)) {
          final pid = s['parent_id'] as String?;
          if (pid == null || !parentIds.contains(pid)) continue;

          final status = s['status'] as String?;
          final planType = s['plan_type'] as String?;
          final trialEnd = s['trial_ends_at'] != null ? DateTime.tryParse(s['trial_ends_at'].toString()) : null;
          final periodEnd = s['current_period_end'] != null ? DateTime.tryParse(s['current_period_end'].toString()) : null;

          if (status == 'expired' || status == 'pending') {
            blocked++;
          } else if (planType == 'trial' && trialEnd != null && trialEnd.isBefore(now)) {
            blocked++;
          } else if (planType == 'monthly' && periodEnd != null && periodEnd.isBefore(now)) {
            blocked++;
          }
        }
      }

      final pendingResult = await _supabase
          .from('payment_transactions')
          .select('id')
          .eq('status', 'pending');

      final schoolsResult = await _supabase
          .from('schools')
          .select('id')
          .eq('country_code', widget.countryCode);

      setState(() {
        _blockedCount = blocked;
        _pendingPaymentsCount = List<Map<String, dynamic>>.from(pendingResult).length;
        _schoolsCount = List<Map<String, dynamic>>.from(schoolsResult).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String get _countryName {
    switch (widget.countryCode) {
      case '+225': return '🇨🇮 Côte d\'Ivoire';
      case '+237': return '🇨🇲 Cameroun';
      case '+221': return '🇸🇳 Sénégal';
      case '+233': return '🇬🇭 Ghana';
      case '+226': return '🇧🇫 Burkina Faso';
      case '+241': return '🇬🇦 Gabon';
      default: return widget.countryCode;
    }
  }

  void _logout() {
    context.read<auth.AuthBloc>().add(auth.LogoutRequested());
    AppRoutes.logout(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text(
          'Espace Assistant',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        // ✅ Anti-overflow : icônes compactes
        actionsIconTheme: const IconThemeData(size: 20),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: _loadStats,
          ),
          // ✅ BOUTON DÉCONNEXION VISIBLE
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: _logout,
          ),
          const SizedBox(width: 8), // ✅ Marge droite pour éviter le chevauchement
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // ✅ Padding bottom 100
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.violetGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.violet.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zone de couverture',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _countryName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _buildHeaderChip('$_schoolsCount écoles', Icons.school),
                              _buildHeaderChip('$_blockedCount bloqués', Icons.block),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            'Bloqués', '$_blockedCount', Icons.block, Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildKpiCard(
                            'Paiements', '$_pendingPaymentsCount', Icons.hourglass_top, Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildKpiCard(
                            'Écoles', '$_schoolsCount', Icons.school, const Color(0xFF6C63FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Modules d\'activité',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.nightBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildModuleCard(
                      icon: Icons.support_agent,
                      title: 'Support Client',
                      subtitle: 'Parents bloqués, fiches détaillées, actions rapides',
                      color: Colors.red,
                      badge: _blockedCount > 0 ? '$_blockedCount' : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupportDashboardPage(countryCode: widget.countryCode),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildModuleCard(
                      icon: Icons.trending_up,
                      title: 'Commercial',
                      subtitle: 'Stats, relances, écoles prospects, parents à contacter',
                      color: const Color(0xFF6C63FF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommercialDashboardPage(countryCode: widget.countryCode),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildModuleCard(
                      icon: Icons.payment,
                      title: 'Abonnements',
                      subtitle: 'Validation paiements, relances, stats abonnements',
                      color: Colors.green,
                      badge: _pendingPaymentsCount > 0 ? '$_pendingPaymentsCount' : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionDashboardPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.bisDark),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // ✅ Expanded pour éviter overflow du titre
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.nightBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}