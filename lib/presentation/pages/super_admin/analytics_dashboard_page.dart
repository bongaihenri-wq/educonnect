// lib/presentation/pages/super_admin/analytics_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _todayEvents = [];
  List<Map<String, dynamic>> _topScreens = [];
  List<Map<String, dynamic>> _dau = [];
  List<Map<String, dynamic>> _recentEvents = [];
  List<Map<String, dynamic>> _userActivity = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Events du jour (depuis la vue)
      final todayResponse =
          await _supabase.from('analytics_today_events').select().limit(20);

      // 2. Top écrans
      final screensResponse =
          await _supabase.from('analytics_top_screens').select().limit(10);

      // 3. DAU
      final dauResponse = await _supabase
          .from('analytics_daily_active_users')
          .select()
          .limit(7);

      // 4. Events récents (depuis la vue - bypass RLS)
      final recentResponse = await _supabase
          .from('analytics_events_all')
          .select()
          .order('timestamp', ascending: false)
          .limit(50);

      // 5. Activité par utilisateur (RPC avec jointure automatique)
      final userActivityResponse = await _supabase
          .rpc('get_analytics_events_with_users', params: {'limit_count': 100});

      print('✅ Events récents: ${recentResponse.length}');
      print('✅ Activité utilisateurs: ${userActivityResponse.length}');

      setState(() {
        _todayEvents = List<Map<String, dynamic>>.from(todayResponse);
        _topScreens = List<Map<String, dynamic>>.from(screensResponse);
        _dau = List<Map<String, dynamic>>.from(dauResponse);
        _recentEvents = List<Map<String, dynamic>>.from(recentResponse);
        _userActivity = List<Map<String, dynamic>>.from(userActivityResponse);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Erreur _loadData: $e');
      print(stackTrace);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ✅ Helper : Nom d'écran lisible
  String _getReadableScreenName(String? rawName) {
    if (rawName == null || rawName.isEmpty) return 'Inconnu';

    final Map<String, String> screenNames = {
      '/login': 'Page de connexion',
      '/parent/dashboard': 'Dashboard Parent',
      '/teacher/dashboard': 'Dashboard Enseignant',
      '/admin/dashboard': 'Dashboard Admin',
      '/super-admin/dashboard': 'Dashboard Super Admin',
      '/super-admin/subscription-dashboard': 'Suivi Abonnements',
      '/super-admin/school-management': 'Gestion Écoles',
      '/child-detail': 'Détail Élève',
      '/': 'Page d\'accueil',
      'MaterialPageRoute': 'Navigation',
      '_PopupMenuRoute': 'Menu popup',
      'DialogRoute': 'Boîte de dialogue',
    };

    for (final entry in screenNames.entries) {
      if (rawName.contains(entry.key)) {
        return entry.value;
      }
    }

    return rawName;
  }

  // ✅ Helper : Nom d'event lisible
  String _getReadableEventName(String? rawName) {
    if (rawName == null || rawName.isEmpty) return 'Inconnu';

    final Map<String, String> eventNames = {
      'app_launched': '🚀 App lancée',
      'app_resumed': '▶️ App reprise',
      'app_paused': '⏸️ App en pause',
      'app_terminated': '⏹️ App fermée',
      'login_screen_viewed': '👁️ Écran login vu',
      'login_attempted': '🔑 Tentative connexion',
      'login_success': '✅ Connexion réussie',
      'login_failed': '❌ Connexion échouée',
      'logout': '🚪 Déconnexion',
      'screen_viewed': '👁️ Écran vu',
      'parent_dashboard_loaded': '📊 Dashboard parent',
      'teacher_dashboard_loaded': '📊 Dashboard enseignant',
      'attendance_taken': '✅ Appel fait',
      'grade_entered': '📝 Note saisie',
      'homework_assigned': '📚 Devoir assigné',
      'error_occurred': '⚠️ Erreur',
      'empty_state_shown': '📭 Données vides',
    };

    return eventNames[rawName] ?? rawName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        backgroundColor: AppTheme.violet,
        title: const Text('📊 Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildKpiCards(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Events Aujourd\'hui'),
                  _buildTodayEventsTable(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Écrans les plus vus'),
                  _buildTopScreensTable(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('DAU (7 derniers jours)'),
                  _buildDauTable(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('👤 Activité par utilisateur'),
                  _buildUserActivityTable(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Events Récents (50 derniers)'),
                  _buildRecentEventsTable(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCards() {
    final totalToday =
        _todayEvents.fold<int>(0, (sum, e) => sum + (e['count'] as int? ?? 0));
    final uniqueUsers = _todayEvents.fold<int>(
        0, (sum, e) => sum + (e['unique_users'] as int? ?? 0));

    return Row(
      children: [
        Expanded(
            child:
                _buildKpiCard('Events Total', '$totalToday', Icons.analytics)),
        Expanded(
            child: _buildKpiCard(
                'Utilisateurs Uniques', '$uniqueUsers', Icons.people)),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.violet, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.nightBlue),
      ),
    );
  }

  Widget _buildTodayEventsTable() {
    final rows = _todayEvents
        .map((e) => <String>[
              _getReadableEventName(e['event_name']),
              (e['count'] ?? 0).toString(),
              (e['unique_users'] ?? 0).toString(),
            ])
        .toList();

    return _buildDataTable(
      headers: const ['Event', 'Count', 'Utilisateurs'],
      rows: rows,
    );
  }

  Widget _buildTopScreensTable() {
    final rows = _topScreens
        .map((e) => <String>[
              _getReadableScreenName(e['screen']?.toString()),
              (e['views'] ?? 0).toString(),
              (e['unique_users'] ?? 0).toString(),
            ])
        .toList();

    return _buildDataTable(
      headers: const ['Écran', 'Vues', 'Utilisateurs uniques'],
      rows: rows,
    );
  }

  Widget _buildDauTable() {
    final rows = _dau
        .map((e) => <String>[
              (e['date'] ?? '').toString().substring(0, 10),
              (e['role'] ?? 'N/A').toString(),
              (e['dau'] ?? 0).toString(),
              (e['sessions'] ?? 0).toString(),
            ])
        .toList();

    return _buildDataTable(
      headers: const ['Date', 'Rôle', 'DAU', 'Sessions'],
      rows: rows,
    );
  }

  Widget _buildUserActivityTable() {
    print('🔍 _userActivity length: ${_userActivity.length}');

    if (_userActivity.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.person_off, color: Colors.grey[400], size: 48),
              const SizedBox(height: 8),
              Text(
                'Aucune activité utilisateur',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Grouper par utilisateur (user_name vient de la RPC)
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final event in _userActivity) {
      final userName = event['user_name']?.toString() ?? 'Anonyme';
      grouped.putIfAbsent(userName, () => []).add(event);
    }

    print('🔍 Grouped users: ${grouped.keys.toList()}');

    final rows = grouped.entries.take(20).map((entry) {
      final userName = entry.key;
      final events = entry.value;
      final lastEvent = events.first;
      final role = lastEvent['role']?.toString() ?? 'Inconnu';
      final lastActivity =
          lastEvent['timestamp']?.toString().substring(11, 16) ?? '--:--';
      final eventCount = events.length.toString();

      return <String>[
        userName,
        role,
        lastActivity,
        eventCount,
      ];
    }).toList();

    return _buildDataTable(
      headers: const ['Utilisateur', 'Rôle', 'Dernière activité', 'Events'],
      rows: rows,
    );
  }

  Widget _buildRecentEventsTable() {
    final rows = _recentEvents.map((e) {
      final userId = (e['user_id'] ?? '').toString();
      final userShort =
          userId.length > 8 ? userId.substring(0, 8) + '...' : userId;

      return <String>[
        e['timestamp']?.toString().substring(11, 16) ?? '',
        _getReadableEventName(e['event_name']),
        userShort,
        e['role'] ?? 'N/A',
      ];
    }).toList();

    return _buildDataTable(
      headers: const ['Heure', 'Event', 'User', 'Rôle'],
      rows: rows,
    );
  }

  Widget _buildDataTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: headers
              .map((h) => DataColumn(
                  label: Text(h,
                      style: const TextStyle(fontWeight: FontWeight.bold))))
              .toList(),
          rows: rows.map((row) {
            return DataRow(
              cells: row.map((cell) => DataCell(Text(cell))).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
