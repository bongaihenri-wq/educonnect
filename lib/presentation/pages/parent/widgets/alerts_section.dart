// lib/presentation/pages/parent/widgets/alerts_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/theme.dart';
import '../../../blocs/auth_bloc/auth_bloc.dart';
import '/services/child_detail_service.dart';
import '../parent_alerts_page.dart';
import '../child_detail_page.dart';

class AlertsSection extends StatefulWidget {
  const AlertsSection({super.key});

  @override
  State<AlertsSection> createState() => _AlertsSectionState();
}

class _AlertsSectionState extends State<AlertsSection> {
  final _service = ChildDetailService();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  List<Map<String, dynamic>> _absences = [];
  List<Map<String, dynamic>> _retards = [];
  List<Map<String, dynamic>> _homeworks = [];
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _latestGrade;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final state = context.read<AuthBloc>().state;
    String? studentId;

    if (state is ParentAuthenticated) {
      studentId = state.studentId;
    } else if (state is Authenticated) {
      try {
        final parentData = await _supabase
            .from('parent_students')
            .select('student_id')
            .eq('parent_id', state.userId)
            .single();
        studentId = parentData['student_id'] as String?;
      } catch (e) {
        debugPrint('Erreur récupération studentId: $e');
      }
    }

    if (studentId == null || studentId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    // ─── 1. ABSENCES & RETARDS ───
    final allAlerts = await _service.getRecentAlerts(studentId);
    _absences = allAlerts.where((a) {
      final type = a['type'] as String?;
      final date = _parseDate(a['date'] ?? a['time']);
      return type == 'absence' && date != null && date.isAfter(yesterday);
    }).toList();
    _retards = allAlerts.where((a) {
      final type = a['type'] as String?;
      final date = _parseDate(a['date'] ?? a['time']);
      return type == 'late' && date != null && date.isAfter(yesterday);
    }).toList();

    // ─── 2. NOTES ───
    final grades = await _service.getGrades(studentId);
    final recentGrades = grades.where((g) {
      final date = _parseDate(g['date']);
      return date != null && date.isAfter(yesterday);
    }).toList();
    _latestGrade = recentGrades.isNotEmpty ? recentGrades.first : null;

    // ─── 3. MESSAGES 24h ───
    try {
      final msgList = await _supabase
          .from('comments')
          .select('''
            id,
            content,
            created_at,
            target_subject,
            is_read,
            app_users!fk_comments_teacher(first_name, last_name)
          ''')
          .eq('student_id', studentId)
          .eq('recipient_type', 'parent')
          .gte('created_at', yesterday.toIso8601String())
          .order('created_at', ascending: false);
      _messages = List<Map<String, dynamic>>.from(msgList);
    } catch (e) {
      debugPrint('Erreur récupération messages: $e');
    }

    // ─── 4. DEVOIRS ───
    try {
      final studentData = await _supabase
          .from('students')
          .select('class_id')
          .eq('id', studentId)
          .maybeSingle();
      final classId = studentData?['class_id'] as String?;

      if (classId != null) {
        final hwList = await _supabase
            .from('homeworks')
            .select('''
              id,
              description,
              due_date,
              due_time,
              created_at,
              subjects(name),
              app_users!teacher_id(first_name, last_name)
            ''')
            .eq('class_id', classId)
            .gte('created_at', yesterday.toIso8601String())
            .order('created_at', ascending: false);
        _homeworks = List<Map<String, dynamic>>.from(hwList);
      }
    } catch (e) {
      debugPrint('Erreur récupération devoirs: $e');
    }

    setState(() => _isLoading = false);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    if (value is DateTime) return value;
    return null;
  }

  int get _totalAlerts =>
      _absences.length + _retards.length + _homeworks.length + _messages.length + (_latestGrade != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── TITRE AVEC BADGE ANIMÉ ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Alertes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.nightBlue,
                      ),
                    ),
                    if (_totalAlerts > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.red, Colors.redAccent],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$_totalAlerts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _navigateToAlertsPage(context),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text(
                    'Tout voir',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.violet))
                : _buildUnifiedCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedCard() {
    if (_totalAlerts == 0) {
      return _buildNoAlertCard();
    }
    return _buildAlertListCard();
  }

  // ═══════════════════════════════════════════════════
  // ÉTAT VIDE - DESIGN RASSURANT
  // ═══════════════════════════════════════════════════
  Widget _buildNoAlertCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.mint.withOpacity(0.15),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.mint.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.mint.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle,
              color: AppTheme.mint,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune Alerte',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.mint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Votre enfant va bien !',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.mint.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rien à signaler ces dernières 24h',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // LISTE DES ALERTES - DESIGN PREMIUM
  // ═══════════════════════════════════════════════════
  Widget _buildAlertListCard() {
    final items = <Widget>[];

    // 1. ABSENCES
    for (final a in _absences) {
      final schedule = a['schedules'] as Map<String, dynamic>?;
      final subject = schedule?['subjects']?['name'] as String? ?? 'Cours';
      final startTime = schedule?['start_time'] as String? ?? '';
      final date = _parseDate(a['date'] ?? a['time']);
      final dateStr = date != null
          ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}'
          : '';

      items.add(_buildAlertItem(
        icon: Icons.person_off,
        color: Colors.red,
        bgColor: Colors.red.withOpacity(0.08),
        title: 'Absence',
        subtitle: subject,
        detail: startTime.isNotEmpty
            ? 'Le $dateStr à $startTime'
            : (dateStr.isNotEmpty ? 'Le $dateStr' : "Aujourd'hui"),
        action: 'Détails',
        actionColor: Colors.red,
        onTap: () => _navigateToAlertsPage(context),
      ));
    }

    // 2. RETARDS
    for (final r in _retards) {
      final schedule = r['schedules'] as Map<String, dynamic>?;
      final subject = schedule?['subjects']?['name'] as String? ?? 'Cours';
      final startTime = schedule?['start_time'] as String? ?? '';
      final date = _parseDate(r['date'] ?? r['time']);
      final dateStr = date != null
          ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}'
          : '';

      items.add(_buildAlertItem(
        icon: Icons.timer,
        color: Colors.orange,
        bgColor: Colors.orange.withOpacity(0.08),
        title: 'Retard',
        subtitle: subject,
        detail: startTime.isNotEmpty
            ? 'Le $dateStr à $startTime'
            : (dateStr.isNotEmpty ? 'Le $dateStr' : "Aujourd'hui"),
        action: 'Détails',
        actionColor: Colors.orange,
        onTap: () => _navigateToAlertsPage(context),
      ));
    }

    // 3. MESSAGES
    for (final msg in _messages) {
      final teacher = msg['app_users'] as Map<String, dynamic>?;
      final teacherName = teacher != null
          ? '${teacher['first_name']} ${teacher['last_name']}'.trim()
          : 'Enseignant';
      final subject = msg['target_subject'] as String? ?? '';
      final isRead = msg['is_read'] as bool? ?? true;

      items.add(_buildAlertItem(
        icon: Icons.chat_bubble,
        color: AppTheme.violet,
        bgColor: AppTheme.violet.withOpacity(0.08),
        title: 'Message',
        subtitle: teacherName,
        detail: subject.isNotEmpty ? subject : 'Nouveau message',
        action: 'Lire',
        actionColor: AppTheme.violet,
        isUnread: !isRead,
        onTap: () => _navigateToMessages(context),
      ));
    }

    // 4. DEVOIRS
    for (final hw in _homeworks) {
      final subject = (hw['subjects'] as Map<String, dynamic>?)?['name'] ?? 'Matière';
      final dueDate = hw['due_date'] as String?;
      final dueTime = hw['due_time'] as String?;

      String dueDateStr = '';
      if (dueDate != null) {
        try {
          final dt = DateTime.parse(dueDate);
          dueDateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
        } catch (_) {
          dueDateStr = dueDate;
        }
      }

      items.add(_buildAlertItem(
        icon: Icons.assignment,
        color: AppTheme.teal,
        bgColor: AppTheme.teal.withOpacity(0.08),
        title: 'Devoir',
        subtitle: subject,
        detail: 'À rendre${dueDateStr.isNotEmpty ? ' le $dueDateStr' : ''}${dueTime != null ? ' à $dueTime' : ''}',
        action: 'Voir',
        actionColor: AppTheme.teal,
        onTap: () => _navigateToMessages(context),
      ));
    }

    // 5. NOTE
    if (_latestGrade != null) {
      final grade = _latestGrade!;
      final score = (grade['score'] as num).toDouble();
      final maxScore = (grade['max_score'] as num?)?.toDouble() ?? 20.0;
      final subject = grade['subjects']?['name'] ?? 'Matière';
      final noteSur20 = maxScore > 0 ? (score / maxScore) * 20 : 0.0;

      Color noteColor;
      if (noteSur20 >= 14) noteColor = Colors.green;
      else if (noteSur20 >= 10) noteColor = Colors.orange;
      else noteColor = Colors.red;

      items.add(_buildAlertItem(
        icon: Icons.school,
        color: noteColor,
        bgColor: noteColor.withOpacity(0.08),
        title: 'Note',
        subtitle: subject,
        detail: '${noteSur20.toStringAsFixed(1)}/20',
        action: 'Voir',
        actionColor: noteColor,
        onTap: () => _navigateToNotes(context),
      ));
    }

    // Séparateurs élégants
    final children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (i < items.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              color: Colors.grey.shade100,
            ),
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // ITEM D'ALERTE PREMIUM
  // ═══════════════════════════════════════════════════
  Widget _buildAlertItem({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String detail,
    required String action,
    required Color actionColor,
    bool isUnread = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─── ICÔNE AVEC BADGE ───
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                if (isUnread)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // ─── CONTENU ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne type + matière
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '• $subtitle',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.nightBlue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Détail (date/heure/note)
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ─── BOUTON ACTION COMPACT ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: actionColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action,
                    style: TextStyle(
                      fontSize: 12,
                      color: actionColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: actionColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAlertsPage(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is! ParentAuthenticated || state.studentId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentAlertsPage(
          studentId: state.studentId,
          studentName: state.studentName,
        ),
      ),
    );
  }

  void _navigateToMessages(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is! ParentAuthenticated || state.studentId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildDetailPage(
          studentId: state.studentId,
          studentName: state.studentName,
          studentMatricule: state.studentMatricule,
          className: state.className,
          parentName: '${state.firstName} ${state.lastName}',
          schoolName: state.schoolName,
          schoolId: state.schoolId,
          initialTab: 3,
        ),
      ),
    );
  }

  void _navigateToNotes(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is! ParentAuthenticated || state.studentId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildDetailPage(
          studentId: state.studentId,
          studentName: state.studentName,
          studentMatricule: state.studentMatricule,
          className: state.className,
          parentName: '${state.firstName} ${state.lastName}',
          schoolName: state.schoolName,
          schoolId: state.schoolId,
          initialTab: 1,
        ),
      ),
    );
  }
}