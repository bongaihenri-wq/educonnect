// lib/features/payments/pages/school_accounting_page.dart
import 'package:educonnect/features/payments/widgets/payment_tab_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/presentation/blocs/auth_bloc/auth_bloc.dart';
import '../data/payment_repository.dart';
import '../models/payment_status_dto.dart';
import '../widgets/pilotage_tab.dart';
import '../widgets/relances_tab.dart';
import '../widgets/students_tab.dart';
import 'package:educonnect/features/updates/widgets/update_banner.dart';

class SchoolAccountingPage extends StatefulWidget {
  final String schoolId;
  const SchoolAccountingPage({super.key, required this.schoolId});

  @override
  State<SchoolAccountingPage> createState() => _SchoolAccountingPageState();
}

class _SchoolAccountingPageState extends State<SchoolAccountingPage>
    with SingleTickerProviderStateMixin {
  final _repo = PaymentRepository(Supabase.instance.client);
  late final TabController _tabController;

  // Données partagées aux onglets
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _history = [];
  List<PaymentStatusDto> _statuses = [];
  List<Map<String, dynamic>> _lateStudents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    PaymentTabEvents.instance.listeners.add(_reloadAll);
    _reloadAll();
  }

  @override
  void dispose() {
    PaymentTabEvents.instance.listeners.remove(_reloadAll);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reloadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getDashboardStats(widget.schoolId),
        _repo.getImportHistory(widget.schoolId),
        _repo.getStatusByClass(widget.schoolId),
        _repo.getLateStudentsWithParents(widget.schoolId),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _history = results[1] as List<Map<String, dynamic>>;
        _statuses = results[2] as List<PaymentStatusDto>;
        _lateStudents = results[3] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comptabilité Scolarité'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: _reloadAll,
          ),
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard, size: 18), text: 'Pilotage'),
            Tab(icon: Icon(Icons.people, size: 18), text: 'Élèves'),
            Tab(icon: Icon(Icons.campaign, size: 18), text: 'Relances'),
          ],
        ),
      ),
      body: Column(
        children: [
          const UpdateBanner(), // ✅ ici, direct sans wrapper
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                PilotageTab(
                  stats: _stats,
                  history: _history,
                  loading: _loading,
                  onRefresh: _reloadAll,
                ),
                StudentsTab(
                  repo: _repo,
                  schoolId: widget.schoolId,
                  statuses: _statuses,
                  loading: _loading,
                ),
                RelancesTab(
                  schoolId: widget.schoolId,
                  lateStudents: _lateStudents,
                  loading: _loading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
