// lib/presentation/pages/super_admin/subscriptions/subscription_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/subscription_service.dart';
import '../../../blocs/auth_bloc/auth_bloc.dart' as auth;
import 'tabs/subscriptions_tab.dart';
import 'tabs/payments_tab.dart';
import 'tabs/relaunch_tab.dart';

class SubscriptionDashboardPage extends StatefulWidget {
  const SubscriptionDashboardPage({super.key});

  @override
  State<SubscriptionDashboardPage> createState() => _SubscriptionDashboardPageState();
}

class _SubscriptionDashboardPageState extends State<SubscriptionDashboardPage> {
  late final SubscriptionService _service;
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  List<Map<String, dynamic>> _schools = [];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _parentsToRelaunch = [];
  
  bool _isLoading = true;
  String? _selectedSchool;
  String? _selectedCountry;
  String? _selectedStatus;
  String _searchQuery = '';
  String? _selectedRelanceStatus;
  String _relanceSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _service = SubscriptionService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final List<dynamic> results = await Future.wait([
        _service.getAllSubscriptions(
          schoolId: _selectedSchool,
          country: _selectedCountry,
          status: _selectedStatus,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        ),
        _service.getPendingPayments(),
        _service.getSchoolsForFilter(),
        _service.getStats(),
        _service.getParentsToRelaunch(),
      ]);

      setState(() {
        _subscriptions = List<Map<String, dynamic>>.from(results[0]);
        _pendingPayments = List<Map<String, dynamic>>.from(results[1]);
        _schools = List<Map<String, dynamic>>.from(results[2]);
        _stats = results[3] is Map ? Map<String, dynamic>.from(results[3]) : {};
        _parentsToRelaunch = List<Map<String, dynamic>>.from(results[4]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadRelaunchData() async {
    try {
      final parents = await _service.getParentsToRelaunch(
        schoolId: _selectedSchool,
        country: _selectedCountry,
        activityStatus: _selectedRelanceStatus,
        searchQuery: _relanceSearchQuery.isEmpty ? null : _relanceSearchQuery,
      );
      setState(() => _parentsToRelaunch = parents);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur relance: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _onFilterChanged({String? school, String? country, String? status, String? search}) {
    setState(() {
      _selectedSchool = school;
      _selectedCountry = country;
      _selectedStatus = status;
      if (search != null) _searchQuery = search;
    });
    _loadData();
  }

  // ✅ CORRIGÉ : Ajout AssistantAuthenticated
  Future<void> _validatePayment(String transactionId) async {
    try {
      final authState = context.read<auth.AuthBloc>().state;
      String? adminId;
      
      if (authState is auth.SuperAdminAuthenticated) {
        adminId = authState.userId;
      } else if (authState is auth.AdminAuthenticated) {
        adminId = authState.userId;
      } else if (authState is auth.AssistantAuthenticated) {
        adminId = authState.userId;
      } else if (authState is auth.Authenticated) {
        adminId = authState.userId;
      }

      if (adminId == null || adminId.isEmpty) {
        throw Exception('Admin non connecté');
      }

      final result = await _service.validatePayment(
        transactionId: transactionId,
        adminId: adminId,
      );

      if (result['success'] == true) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${result['message']}'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ ${result['message']}'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur validation: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectPayment(String transactionId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le paiement'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Raison du rejet...', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'Paiement non reçu'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        await _service.rejectPayment(transactionId: transactionId, reason: reason);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Paiement rejeté'), backgroundColor: Colors.orange),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _callParent(String parentId) => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('📞 Appel en cours...')),
  );

  void _sendSMS(String parentId) => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('📱 SMS envoyé')),
  );

  void _viewDetails(String parentId) {}

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingPayments.length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('💰 Suivi des Abonnements'),
          backgroundColor: const Color(0xFF6B4EFF),
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(icon: Icon(Icons.dashboard), text: 'Abonnements'),
              Tab(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.payment),
                ),
                text: 'Paiements',
              ),
              const Tab(icon: Icon(Icons.phone_forwarded), text: 'À relancer'),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Actualiser'),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  SubscriptionsTab(
                    stats: _stats,
                    subscriptions: _subscriptions,
                    schools: _schools,
                    selectedSchool: _selectedSchool,
                    selectedCountry: _selectedCountry,
                    selectedStatus: _selectedStatus,
                    searchQuery: _searchQuery,
                    onFilterChanged: _onFilterChanged,
                    onRefresh: _loadData,
                  ),
                 PaymentsTab(
                    pendingPayments: _pendingPayments,
                    onRefresh: _loadData,
                    onValidate: _validatePayment,
                    onReject: _rejectPayment,
                    getHistory: ({String? status, bool includeArchived = false}) => 
                    _service.getPaymentHistory(status: status, includeArchived: includeArchived),
                    onArchive: (id) => _service.archivePayment(id),
                   ),
                  RelaunchTab(
                    parentsToRelaunch: _parentsToRelaunch,
                    selectedRelanceStatus: _selectedRelanceStatus,
                    relanceSearchQuery: _relanceSearchQuery,
                    onStatusChanged: (value) {
                      setState(() => _selectedRelanceStatus = value);
                      _loadRelaunchData();
                    },
                    onSearchChanged: (value) {
                      _relanceSearchQuery = value;
                      Future.delayed(const Duration(milliseconds: 500), _loadRelaunchData);
                    },
                    onRefresh: _loadRelaunchData,
                    onCall: _callParent,
                    onSendSMS: _sendSMS,
                    onViewDetails: _viewDetails,
                  ),
                ],
              ),
      ),
    );
  }
}