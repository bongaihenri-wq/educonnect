// lib/presentation/pages/admin/teachers_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart'; // ✅ AJOUTÉ : pour AppRoutes.adminSendMessage
import '../../../services/admin_stats_service.dart';
import '../../blocs/auth_bloc/auth_bloc.dart' as auth;

class TeachersListPage extends StatefulWidget {
  const TeachersListPage({super.key});

  @override
  State<TeachersListPage> createState() => _TeachersListPageState();
}

class _TeachersListPageState extends State<TeachersListPage> {
  final AdminStatsService _statsService = AdminStatsService();
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _schedules =
      []; // ✅ AJOUTÉ : emplois du temps (lien enseignant ↔ classe)
  bool _isLoading = true;
  String? _schoolId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    try {
      final state = context.read<auth.AuthBloc>().state;
      if (state is auth.Authenticated) {
        _schoolId = state.schoolId;
      }

      if (_schoolId == null) {
        setState(() {
          _isLoading = false;
          _error = 'School ID non trouvé';
        });
        return;
      }

      final teachers =
          await _statsService.getTeachersWithAttendanceStats(_schoolId!);

      final enrichedTeachers = teachers.map((teacher) {
        return teacher as Map<String, dynamic>;
      }).toList();

      // ✅ AJOUTÉ : charger les emplois du temps pour le regroupement par classe
      await _loadSchedules();

      if (mounted) {
        setState(() {
          _teachers = enrichedTeachers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  // ✅ AJOUTÉ : charge les liaisons enseignant ↔ classe (fallback silencieux si erreur)
  Future<void> _loadSchedules() async {
    try {
      final data = await Supabase.instance.client
          .from('schedules')
          .select('teacher_id, class_id, classes(name)')
          .eq('school_id', _schoolId!)
          .eq('is_active', true);
      _schedules = List<Map<String, dynamic>>.from(data);
    } catch (_) {
      _schedules =
          []; // pas de regroupement possible → tout ira dans "Sans classe assignée"
    }
  }

  // ✅ AJOUTÉ : regroupe les enseignants par classe (un enseignant peut apparaître dans plusieurs classes)
  Map<String, List<Map<String, dynamic>>> _groupTeachersByClass() {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    final Set<String> assignedTeacherIds = {};
    final byId = {for (var t in _teachers) t['teacher_id'].toString(): t};

    for (final s in _schedules) {
      final tid = s['teacher_id']?.toString();
      final className = s['classes']?['name']?.toString() ?? 'Classe inconnue';
      if (tid == null || !byId.containsKey(tid)) continue;
      groups.putIfAbsent(className, () => []);
      if (!groups[className]!.any((t) => t['teacher_id'].toString() == tid)) {
        groups[className]!.add(byId[tid]!);
      }
      assignedTeacherIds.add(tid);
    }

    final unassigned = _teachers
        .where((t) => !assignedTeacherIds.contains(t['teacher_id'].toString()))
        .toList();
    if (unassigned.isNotEmpty) {
      groups['Sans classe assignée'] = unassigned;
    }

    final sortedKeys =
        groups.keys.where((k) => k != 'Sans classe assignée').toList()..sort();
    if (groups.containsKey('Sans classe assignée')) {
      sortedKeys.add('Sans classe assignée');
    }
    return {for (var k in sortedKeys) k: groups[k]!};
  }

  // ✅ AJOUTÉ : construit la liste avec en-têtes de classe
  List<Widget> _buildGroupedList() {
    final groups = _groupTeachersByClass();
    final widgets = <Widget>[];
    groups.forEach((className, teachers) {
      widgets.add(_buildClassHeader(className, teachers.length));
      widgets.addAll(teachers.map(_buildTeacherCard));
    });
    return widgets;
  }

  // ✅ AJOUTÉ : en-tête de classe
  Widget _buildClassHeader(String className, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.class_, size: 18, color: AppTheme.violet),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              className,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.violet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count ens.',
              style: TextStyle(
                color: AppTheme.violet,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text('Enseignants'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadTeachers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddTeacherDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _teachers.isEmpty
                  ? _buildEmptyWidget()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children:
                          _buildGroupedList(), // ✅ MODIFIÉ : liste groupée par classe
                    ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    final teacherName = teacher['teacher_name'] ?? 'Inconnu';
    final email = teacher['email'] ?? 'Email non défini';
    final phone = teacher['phone'] ?? 'Téléphone non défini';

    final scheduledCourses = teacher['scheduled_courses'] ?? 0;
    final callsThisMonth = teacher['calls_this_month'] ?? 0;
    final totalStudentRecords = teacher['total_student_records'] ?? 0;
    final presenceRate = teacher['student_presence_rate'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.violet,
          child: Text(
            teacherName.isNotEmpty ? teacherName[0] : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          teacherName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$scheduledCourses cours • $callsThisMonth appels ce mois',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: presenceRate >= 80
                ? Colors.green.withOpacity(0.1)
                : presenceRate >= 60
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$presenceRate%',
            style: TextStyle(
              color: presenceRate >= 80
                  ? Colors.green
                  : presenceRate >= 60
                      ? Colors.orange
                      : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildInfoRow(Icons.email, email),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, phone),
                const SizedBox(height: 16),

                // Stats détaillées
                Row(
                  children: [
                    _buildDetailStat(
                      Icons.check_circle,
                      '$callsThisMonth',
                      'Appels ce mois',
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildDetailStat(
                      Icons.calendar_today,
                      '$scheduledCourses',
                      'Cours programmés',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildDetailStat(
                      Icons.trending_up,
                      '$presenceRate%',
                      'Présence élèves',
                      AppTheme.violet,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Info supplémentaire
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$totalStudentRecords élèves marqués au total',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showTeacherDetails(teacher),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Détails'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _sendMessageToTeacher(teacher),
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          // ✅ sécurité anti-débordement
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailStat(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTeacherDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout enseignant - à implémenter')),
    );
  }

  void _showTeacherDetails(Map<String, dynamic> teacher) {
    final teacherName = teacher['teacher_name'] ?? '';
    final teacherId = teacher['teacher_id'] ?? '';

    Navigator.pushNamed(
      context,
      '/admin/teacher-tracking',
      arguments: {
        'teacher_id': teacherId,
        'teacher_name': teacherName,
        'school_id': _schoolId,
      },
    );
  }

  // ✅ MODIFIÉ : redirige vers la page d'envoi avec l'enseignant pré-sélectionné
  void _sendMessageToTeacher(Map<String, dynamic> teacher) {
    final teacherId = teacher['teacher_id'] ?? '';

    Navigator.pushNamed(
      context,
      AppRoutes.adminSendMessage,
      arguments: {'teacherId': teacherId},
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Erreur: $_error'),
          ElevatedButton(
            onPressed: _loadTeachers,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun enseignant trouvé',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
