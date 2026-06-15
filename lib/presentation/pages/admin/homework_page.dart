// lib/presentation/pages/admin/homework_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../blocs/auth_bloc/auth_bloc.dart' as auth;
import 'widgets/homeworks/homework_filters_bar.dart';
import 'widgets/homeworks/homework_list_view.dart';
import 'widgets/homeworks/homework_empty_state.dart';
import 'widgets/homeworks/homework_error_banner.dart';
import 'widgets/homeworks/homework_detail_dialog.dart';
import 'widgets/homeworks/homework_counter_bar.dart';
import 'widgets/add_homework_dialog.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _homeworks = [];
  bool _isLoading = true;
  String? _schoolId;
  String? _error;
  
  String _selectedFilter = 'tous';
  String _selectedType = 'tous';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _filters = [
    {'value': 'tous', 'label': 'Tous', 'icon': Icons.all_inclusive},
    {'value': 'prevu', 'label': 'Prévus', 'icon': Icons.schedule},
    {'value': 'en_cours', 'label': 'En cours', 'icon': Icons.play_circle},
    {'value': 'acheve', 'label': 'Achevés', 'icon': Icons.check_circle},
  ];

  final List<Map<String, dynamic>> _types = [
    {'value': 'tous', 'label': 'Tous types'},
    {'value': 'devoir', 'label': 'Devoirs'},
    {'value': 'controle', 'label': 'Contrôles'},
    {'value': 'examen', 'label': 'Examens'},
    {'value': 'interro', 'label': 'Interros'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSchoolId());
  }

  void _initSchoolId() {
    final state = context.read<auth.AuthBloc>().state;
    String? extractedSchoolId;
    print('🔍 DIAGNOSTIC STATE TYPE = ${state.runtimeType}');
    if (state is auth.AdminAuthenticated) {
      extractedSchoolId = state.schoolId;
     print('🔍 AdminAuthenticated - schoolId = $extractedSchoolId');

    } else if (state is auth.SuperAdminAuthenticated) {
      extractedSchoolId = state.schoolId;
      print('🔍 SuperAdminAuthenticated - schoolId = $extractedSchoolId');
    } else if (state is auth.ParentAuthenticated) {
      extractedSchoolId = state.schoolId;
    } else if (state is auth.TeacherAuthenticated) {
      extractedSchoolId = state.schoolId;
    } else if (state is auth.Authenticated) {
      try {
        extractedSchoolId = (state as dynamic).schoolId?.toString();
      } catch (_) {
        extractedSchoolId = null;
      }
    }

    if (extractedSchoolId == null || extractedSchoolId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'School ID non trouvé. Veuillez vous reconnecter.';
      });
      return;
    }

    setState(() => _schoolId = extractedSchoolId);
    _loadHomeworks();
  }

  Future<void> _loadHomeworks() async {
    if (_schoolId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var query = _client
          .from('homeworks')
          .select('''
            id, title, description, type, priority, status,
            due_date, due_time, room, class_id, subject_id, teacher_id,
            completed_at, completed_by, attachments, teacher_comment,
            is_active, created_at, updated_at, school_id
          ''')
          .eq('school_id', _schoolId!)
          .eq('is_active', true);

      if (_selectedFilter != 'tous') query = query.eq('status', _selectedFilter);
      if (_selectedType != 'tous') query = query.eq('type', _selectedType);

      final response = await query.order('due_date', ascending: true);
      final homeworksList = List<Map<String, dynamic>>.from(response);
      
      if (homeworksList.isNotEmpty) await _enrichHomeworks(homeworksList);

      setState(() {
        _homeworks = homeworksList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur chargement: ${e.toString()}';
      });
    }
  }

  Future<void> _enrichHomeworks(List<Map<String, dynamic>> homeworks) async {
    try {
      final classIds = _extractIds(homeworks, 'class_id');
      final subjectIds = _extractIds(homeworks, 'subject_id');
      final teacherIds = _extractIds(homeworks, 'teacher_id');

      final classesMap = await _loadRelatedData('classes', 'id, name, level', classIds);
      final subjectsMap = await _loadRelatedData('subjects', 'id, name', subjectIds);
      final teachersMap = await _loadRelatedData('app_users', 'id, first_name, last_name', teacherIds);

      for (final h in homeworks) {
        h['classes'] = classesMap[h['class_id']?.toString()] ?? {'name': 'Classe inconnue'};
        h['subjects'] = subjectsMap[h['subject_id']?.toString()] ?? {'name': 'Matière inconnue'};
        h['app_users'] = teachersMap[h['teacher_id']?.toString()] ?? {'first_name': 'Enseignant', 'last_name': ''};
      }
    } catch (_) {}
  }

  List<String> _extractIds(List<Map<String, dynamic>> items, String key) {
    return items
        .map((h) => h[key])
        .where((id) => id != null)
        .toSet()
        .cast<String>()
        .toList();
  }

  Future<Map<String, Map<String, dynamic>>> _loadRelatedData(
    String table,
    String select,
    List<String> ids,
  ) async {
    final map = <String, Map<String, dynamic>>{};
    if (ids.isEmpty) return map;

    final response = await _client.from(table).select(select).inFilter('id', ids);
    for (final item in response) {
      map[item['id']] = item;
    }
    return map;
  }

  List<Map<String, dynamic>> get _filteredHomeworks {
    if (_searchQuery.isEmpty) return _homeworks;
    return _homeworks.where((h) {
      final title = h['title']?.toString().toLowerCase() ?? '';
      final subject = h['subjects']?['name']?.toString().toLowerCase() ?? '';
      final classe = h['classes']?['name']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || subject.contains(query) || classe.contains(query);
    }).toList();
  }

  int get _overdueCount => _filteredHomeworks.where(_isOverdue).length;

  bool _isOverdue(Map<String, dynamic> homework) {
    final status = homework['status']?.toString() ?? '';
    if (status == 'acheve' || status == 'annule') return false;
    try {
      final date = DateTime.parse(homework['due_date'].toString());
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _isLoading = true;
    });
    _loadHomeworks();
  }

  void _onTypeChanged(String type) {
    setState(() {
      _selectedType = type;
      _isLoading = true;
    });
    _loadHomeworks();
  }

  void _onSearchChanged(String query) => setState(() => _searchQuery = query);

  void _resetFilters() {
    setState(() {
      _selectedFilter = 'tous';
      _selectedType = 'tous';
      _isLoading = true;
    });
    _loadHomeworks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text('Devoirs & Contrôles'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _schoolId != null ? () => _loadHomeworks() : null,
          ),
        ],
      ),
      floatingActionButton: _schoolId != null
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              backgroundColor: AppTheme.violet,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            )
          : null,
      body: Column(
        children: [
          HomeworkFiltersBar(
            selectedFilter: _selectedFilter,
            selectedType: _selectedType,
            searchQuery: _searchQuery,
            filters: _filters,
            types: _types,
            onFilterChanged: _onFilterChanged,
            onTypeChanged: _onTypeChanged,
            onSearchChanged: _onSearchChanged,
          ),
          HomeworkCounterBar(
            count: _filteredHomeworks.length,
            overdueCount: _overdueCount,
          ),
          const SizedBox(height: 8),
          if (_error != null)
            HomeworkErrorBanner(
              error: _error!,
              onDismiss: () => setState(() => _error = null),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _schoolId == null
                    ? _buildNoSchoolIdState()
                    : _filteredHomeworks.isEmpty
                        ? HomeworkEmptyState(
                            hasFilters: _selectedFilter != 'tous' || _selectedType != 'tous',
                            onResetFilters: _resetFilters,
                          )
                        : HomeworkListView(
                            homeworks: _filteredHomeworks,
                            onTap: _showDetailDialog,
                            onToggleComplete: _toggleComplete,
                            onEdit: _showEditDialog,
                            onDelete: _deleteHomework,
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSchoolIdState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Impossible de charger les devoirs', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text('School ID manquant', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.read<auth.AuthBloc>().add(auth.LogoutRequested()),
          child: const Text('Se reconnecter'),
        ),
      ],
    ),
  );

  void _showAddDialog() => _showHomeworkDialog(null);
  void _showEditDialog(Map<String, dynamic> homework) => _showHomeworkDialog(homework);

  void _showHomeworkDialog(Map<String, dynamic>? homework) {
    if (_schoolId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AddHomeworkDialog(
        schoolId: _schoolId!,
        homework: homework,
        onSubmit: (data) async {
          if (homework == null) {
            await _createHomework(data);
          } else {
            await _updateHomework(homework['id'], data);
          }
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> homework) {
    showDialog(
      context: context,
      builder: (context) => HomeworkDetailDialog(homework: homework),
    );
  }

  Future<void> _createHomework(Map<String, dynamic> data) async {
    try {
      // ✅ LOGS DIAGNOSTIC — AJOUTÉS ICI
      final jwtUserId = _client.auth.currentUser?.id;
      print('🔍 DIAGNOSTIC ADMIN');
      print('🔍 JWT auth.uid() = $jwtUserId');
      print('🔍 Attendu app_users.id = 0625fd1b-5068-46f0-8723-c50efb3950d8');
      print('🔍 Match = ${jwtUserId == '0625fd1b-5068-46f0-8723-c50efb3950d8'}');

      await _client.from('homeworks').insert({
        ...data,
        'school_id': _schoolId,
        'is_active': true,
        'status': data['status'] ?? 'prevu',
      });
      _showSnackBar('✅ Devoir créé avec succès');
      _loadHomeworks();
    } catch (e) {
      _showSnackBar('❌ Erreur création: $e');
    }
  }

  Future<void> _updateHomework(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('homeworks').update(data).eq('id', id);
      _showSnackBar('✅ Devoir mis à jour');
      _loadHomeworks();
    } catch (e) {
      _showSnackBar('❌ Erreur mise à jour: $e');
    }
  }

  Future<void> _toggleComplete(Map<String, dynamic> homework) async {
    final currentStatus = homework['status']?.toString() ?? '';
    final newStatus = currentStatus == 'acheve' ? 'prevu' : 'acheve';
    
    try {
      final updateData = {
        'status': newStatus,
        if (newStatus == 'acheve') ...{
          'completed_at': DateTime.now().toIso8601String(),
          'completed_by': _client.auth.currentUser?.id,
        } else ...{
          'completed_at': null,
          'completed_by': null,
        },
      };
      
      await _client.from('homeworks').update(updateData).eq('id', homework['id']);
      _showSnackBar(newStatus == 'acheve' ? '✅ Marqué comme achevé' : '↩️ Marqué comme prévu');
      _loadHomeworks();
    } catch (e) {
      _showSnackBar('❌ Erreur: $e');
    }
  }

  Future<void> _deleteHomework(Map<String, dynamic> homework) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer "${homework['title']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _client.from('homeworks').update({'is_active': false}).eq('id', homework['id']);
        _showSnackBar('🗑️ Devoir supprimé');
        _loadHomeworks();
      } catch (e) {
        _showSnackBar('❌ Erreur: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}