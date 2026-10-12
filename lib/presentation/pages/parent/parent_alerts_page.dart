// lib/presentation/pages/parent/parent_alerts_page.dart
import 'package:educonnect/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:educonnect/presentation/pages/parent/child_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/services/child_detail_service.dart';
import '../../../config/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ParentAlertsPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const ParentAlertsPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ParentAlertsPage> createState() => _ParentAlertsPageState();
}

class _ParentAlertsPageState extends State<ParentAlertsPage> {
  final _service = ChildDetailService();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _weekAbsences = [];
  List<Map<String, dynamic>> _weekRetards = [];
  List<Map<String, dynamic>> _weekComments = [];
  // Mises à jour scolarité (persistantes jusqu'à clic)
  List<Map<String, dynamic>> _paymentUpdates = [];
  // Messages administration (relances incluses)
  List<Map<String, dynamic>> _adminMessages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    // 1. Absences sur 1 semaine
    final attendance = await _service.getAttendance(widget.studentId);
    final absences = attendance.where((a) {
      final date = DateTime.parse(a['date'] as String);
      final status = a['status'] as String;
      return date.isAfter(sevenDaysAgo) && status == 'absent';
    }).toList();

    // 2. Retards sur 1 semaine
    final retards = attendance.where((a) {
      final date = DateTime.parse(a['date'] as String);
      final status = a['status'] as String;
      return date.isAfter(sevenDaysAgo) && status == 'late';
    }).toList();

    // 3. Commentaires sur 1 semaine
    List<dynamic> commentsResponse = [];
    try {
      commentsResponse = await _supabase
          .from('comments')
          .select('''
            id,
            content,
            created_at,
            sender_type,
            recipient_type,
            target_subject,
            is_read,
            teacher_id,
            app_users!teacher_id(first_name, last_name, role)
          ''')
          .eq('student_id', widget.studentId)
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at', ascending: false);
    } catch (e) {
      debugPrint('Erreur chargement commentaires: $e');
    }

    final recentComments = List<Map<String, dynamic>>.from(commentsResponse);

    // 4. Mises à jour de scolarité (non lues)
    try {
      final rows = await _supabase
          .from('student_notifications')
          .select('id, message, created_at')
          .eq('student_id', widget.studentId)
          .eq('type', 'payment_update')
          .isFilter('read_at', null)
          .order('created_at', ascending: false);
      _paymentUpdates = List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('Erreur chargement notifs scolarité: $e');
    }

    // 5. Messages administration (relances incluses) — 7 derniers jours
    // 5. Messages administration (relances incluses) — 7 derniers jours
    try {
      final authState = context.read<AuthBloc>().state;
      final parentId = authState is ParentAuthenticated ? authState.userId : '';
      final schoolId =
          authState is ParentAuthenticated ? authState.schoolId : '';
      if (parentId.isNotEmpty && schoolId.isNotEmpty) {
        // Deux requêtes fusionnées en Dart (fiabilité > astuce .or())
        final specific = await _supabase
            .from('admin_messages')
            .select('id, title, content, sender_name, priority, created_at')
            .eq('school_id', schoolId)
            .eq('target_parent_id', parentId)
            .gte('created_at', sevenDaysAgo.toIso8601String());

        final broadcast = await _supabase
            .from('admin_messages')
            .select('id, title, content, sender_name, priority, created_at')
            .eq('school_id', schoolId)
            .eq('recipient_type', 'all_parents')
            .gte('created_at', sevenDaysAgo.toIso8601String());

        final merged = <Map<String, dynamic>>[
          ...List<Map<String, dynamic>>.from(specific as List),
          ...List<Map<String, dynamic>>.from(broadcast as List),
        ];
        final seen = <dynamic>{};
        merged.retainWhere((m) => seen.add(m['id']));
        merged.sort((a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String));
        _adminMessages = merged;
        debugPrint('✅ admin_messages chargés: ${_adminMessages.length}');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement admin_messages: $e');
    }

    setState(() {
      _weekAbsences = absences;
      _weekRetards = retards;
      _weekComments = recentComments;
      _isLoading = false;
    });
  }

  // Clic sur une alerte scolarité → marque lu + ouvre Compta
  Future<void> _openCompta(String notificationId) async {
    try {
      await _supabase
          .from('student_notifications')
          .update({'read_at': DateTime.now().toIso8601String()}).eq(
              'id', notificationId);
    } catch (e) {
      debugPrint('Erreur marquage lu: $e');
    }

    setState(() {
      _paymentUpdates.removeWhere((n) => n['id'] == notificationId);
    });

    if (!mounted) return;
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
          initialTab: 4,
        ),
      ),
    );
  }

  // Clic sur un message administration → ouvre l'onglet Messages (index 4)
  void _openMessagesTab() {
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
          initialTab: 4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        backgroundColor: AppTheme.bisLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.nightBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: AppTheme.violet),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Alertes - ${widget.studentName}',
                style: TextStyle(
                  color: AppTheme.nightBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.violet))
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  // ─── SCOLARITÉ — MISES À JOUR (persistantes jusqu'à clic) ───
                  if (_paymentUpdates.isNotEmpty) ...[
                    _buildSectionTitle('Scolarité — mises à jour',
                        Icons.payments, Colors.green.shade700),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final n = _paymentUpdates[index];
                          final date =
                              DateTime.parse(n['created_at'] as String);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.payments,
                                      color: Colors.green.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n['message'] as String,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _openCompta(n['id'] as String),
                                    child: const Text('Voir'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _paymentUpdates.length,
                      ),
                    ),
                  ],

                  // ─── MESSAGES ADMINISTRATION (relances) ───
                  if (_adminMessages.isNotEmpty) ...[
                    _buildSectionTitle('Messages — Administration',
                        Icons.campaign, Colors.orange.shade800),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final m = _adminMessages[index];
                          final date =
                              DateTime.parse(m['created_at'] as String);
                          final priority = m['priority'] as String? ?? 'normal';
                          final isUrgent =
                              priority == 'high' || priority == 'urgent';
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUrgent
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isUrgent
                                      ? Colors.red.shade200
                                      : Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.campaign,
                                      color: isUrgent
                                          ? Colors.red.shade700
                                          : Colors.orange.shade800),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m['title'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                        Text(
                                          m['content'] as String,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _openMessagesTab,
                                    child: const Text('Voir'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _adminMessages.length,
                      ),
                    ),
                  ],

                  // ─── ABSENCES ────────────────────
                  _buildSectionTitle(
                      'Absences (7 derniers jours)', Icons.cancel, Colors.red),
                  _buildAttendanceList(_weekAbsences, 'absent'),

                  // ─── RETARDS ─────────────────────
                  _buildSectionTitle('Retards (7 derniers jours)',
                      Icons.access_time, Colors.orange),
                  _buildAttendanceList(_weekRetards, 'late'),

                  // ─── COMMENTAIRES ────────────────
                  _buildSectionTitle('Commentaires (7 derniers jours)',
                      Icons.chat, AppTheme.violet),
                  _buildCommentsList(),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.nightBlue,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList(List<Map<String, dynamic>> items, String status) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucun ${status == 'absent' ? 'absence' : 'retard'} cette semaine',
                    style: TextStyle(color: Colors.grey.shade500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          final date = DateTime.parse(item['date'] as String);
          final schedule = item['schedules'] as Map<String, dynamic>?;
          final subject = schedule?['subjects']?['name'] ?? 'Cours';
          final time = schedule?['start_time'] ?? '--:--';

          final color = status == 'absent' ? Colors.red : Colors.orange;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    status == 'absent' ? Icons.cancel : Icons.access_time,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.nightBlue,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à $time',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status == 'absent' ? 'Absent' : 'Retard',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: items.length,
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_weekComments.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucun commentaire cette semaine',
                    style: TextStyle(color: Colors.grey.shade500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final comment = _weekComments[index];
          final date = DateTime.parse(comment['created_at'] as String);
          final content = comment['content'] as String? ?? '';
          final senderType = comment['sender_type'] as String? ?? 'teacher';
          final recipientType =
              comment['recipient_type'] as String? ?? 'parent';
          final targetSubject = comment['target_subject'] as String?;
          final isRead = comment['is_read'] as bool? ?? true;

          final teacherData = comment['app_users'] as Map<String, dynamic>?;
          String senderName;
          if (teacherData != null) {
            final firstName = teacherData['first_name'] as String? ?? '';
            final lastName = teacherData['last_name'] as String? ?? '';
            senderName = '$firstName $lastName'.trim();
            if (senderName.isEmpty) senderName = 'Enseignant';
          } else {
            senderName = _getSenderLabel(senderType);
          }

          final recipientLabel = _getRecipientLabel(recipientType);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.violet.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isRead
                      ? AppTheme.violet.withOpacity(0.2)
                      : AppTheme.violet.withOpacity(0.5),
                  width: isRead ? 1 : 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.violet.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.chat, color: AppTheme.violet, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(
                                  'De : $senderName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.nightBlue,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.violet.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    senderType == 'teacher'
                                        ? 'Prof'
                                        : (senderType == 'admin'
                                            ? 'Admin'
                                            : 'Parent'),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.violet,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Pour : $recipientLabel',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.nightBlue,
                      fontSize: 13,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (targetSubject != null) ...[
                        Icon(Icons.book, size: 10, color: AppTheme.violet),
                        const SizedBox(width: 4),
                        Text(
                          targetSubject,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.violet,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      Icon(Icons.access_time,
                          size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        childCount: _weekComments.length,
      ),
    );
  }

  String _getSenderLabel(String senderType) {
    return switch (senderType) {
      'teacher' => 'Enseignant',
      'admin' => 'Administration',
      'parent' => 'Parent',
      _ => 'Expéditeur',
    };
  }

  String _getRecipientLabel(String recipientType) {
    return switch (recipientType) {
      'parent' => 'Parent',
      'student' => 'Élève',
      'teacher' => 'Enseignant',
      'class' => 'Classe',
      _ => 'Destinataire',
    };
  }
}
