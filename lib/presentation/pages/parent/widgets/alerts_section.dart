// lib/presentation/pages/parent/widgets/alerts_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/theme.dart';
import '../../../blocs/auth_bloc/auth_bloc.dart';
import '/services/child_detail_service.dart';
import '../parent_alerts_page.dart';

class AlertsSection extends StatefulWidget {
  const AlertsSection({super.key});

  @override
  State<AlertsSection> createState() => _AlertsSectionState();
}

class _AlertsSectionState extends State<AlertsSection> {
  final _service = ChildDetailService();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentAlerts = [];
  Map<String, dynamic>? _latestGrade;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final state = context.read<AuthBloc>().state;
    print('🔍 [AlertsSection] state type: ${state.runtimeType}');
    
    // ✅ CORRIGÉ : Récupérer studentId de manière robuste
    String? studentId;
    
    if (state is ParentAuthenticated) {
      print('🔍 [AlertsSection] studentId: "${state.studentId}"');
      print('🔍 [AlertsSection] studentName: "${state.studentName}"');
      studentId = state.studentId;
    } else if (state is Authenticated) {
      // Fallback : récupérer depuis parent_students table
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

    final alerts = await _service.getRecentAlerts(studentId);
    final grades = await _service.getGrades(studentId);
    
    // Dernière note des 24h
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    
    // ✅ CORRIGÉ : Parsing défensif des dates
    final recentGrades = grades.where((g) {
      final dateValue = g['date'];
      DateTime? date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      }
      return date != null && date.isAfter(yesterday);
    }).toList();

    // ✅ CORRIGÉ : Messages des dernières 24h avec bonne FK
    final recentMessages = await _supabase
        .from('comments')
        .select('*, app_users!fk_comments_teacher(first_name, last_name)')
        .eq('student_id', studentId)
        .eq('recipient_type', 'parent')
        .eq('sender_type', 'teacher')
        .gte('created_at', yesterday.toIso8601String())
        .order('created_at', ascending: false);

    // ✅ CORRIGÉ : Fusionner messages avec alerts
    final allAlerts = [...alerts];
    for (final msg in recentMessages) {
      final teacher = msg['app_users'] as Map<String, dynamic>?;
      allAlerts.add({
        'type': 'message',
        'date': msg['created_at'],
        'content': msg['content'],
        'teacher_name': teacher != null 
            ? '${teacher['first_name']} ${teacher['last_name']}'
            : 'Enseignant',
        'subject': msg['target_subject'],
        'is_read': msg['is_read'] ?? true,
      });
    }
    
    // Trier par date décroissante
   allAlerts.sort((a, b) {
      DateTime parseDate(dynamic value) {
        if (value == null) return DateTime(1970);
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (_) {
            return DateTime(1970);
          }
        }
        if (value is DateTime) return value;
        return DateTime(1970);
      }
      
      final dateA = parseDate(a['date'] ?? a['time']);
      final dateB = parseDate(b['date'] ?? b['time']);
      return dateB.compareTo(dateA);
    });

    setState(() {
      _recentAlerts = allAlerts;
      _latestGrade = recentGrades.isNotEmpty ? recentGrades.first : null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final absencesRetards = _recentAlerts.where((a) {
      final type = a['type'] as String;
      return type == 'absence' || type == 'late';
    }).toList();

    final hasIssues = absencesRetards.isNotEmpty;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── TITRE + VOIR TOUT ───────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Alertes récentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.nightBlue,
                      ),
                    ),
                    if (hasIssues)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.coral.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${absencesRetards.length}',
                          style: const TextStyle(
                            color: AppTheme.coral,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToAlertsPage(context),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── CARTE 1 : ABSENCES/RETARDS 24H ─
            _buildAttendanceCard(absencesRetards, hasIssues),

            const SizedBox(height: 12),

            // ─── CARTE 2 : DERNIÈRE NOTE ─────
            _buildGradeCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(List<Map<String, dynamic>> issues, bool hasIssues) {
    if (hasIssues) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.coral.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.coral.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.coral.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.coral,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${issues.length} problème${issues.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.coral,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    issues.map((i) {
                      final status = i['type'] == 'absence' ? 'Absence' : 'Retard';
                      return status;
                    }).join(', '),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.coral.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dernières 24h',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.mint.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.mint.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.mint.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppTheme.mint,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aucun problème',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.mint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ni absences ni retards ces dernières 24h',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.mint.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tout va bien !',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard() {
    if (_latestGrade != null) {
      final grade = _latestGrade!;
      final score = (grade['score'] as num).toDouble();
      final maxScore = (grade['max_score'] as num?)?.toDouble() ?? 20.0;
      final subject = grade['subjects']?['name'] ?? 'Matière';
      final noteSur20 = maxScore > 0 ? (score / maxScore) * 20 : 0.0;

      Color color;
      if (noteSur20 >= 14) color = Colors.green;
      else if (noteSur20 >= 10) color = Colors.orange;
      else color = Colors.red;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nouvelle note',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.nightBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$subject : ${noteSur20.toStringAsFixed(1)}/20',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dernières 24h',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inbox_outlined,
              color: Colors.grey.shade500,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pas de nouvelles notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aucune note enregistrée ces dernières 24h',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
}