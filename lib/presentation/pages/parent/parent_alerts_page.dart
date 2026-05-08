// lib/presentation/pages/parent/parent_alerts_page.dart
import 'package:flutter/material.dart';
import '/services/child_detail_service.dart';
import '../../../config/theme.dart';

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
  bool _isLoading = true;
  List<Map<String, dynamic>> _weekAbsences = [];
  List<Map<String, dynamic>> _weekRetards = [];
  List<Map<String, dynamic>> _weekComments = [];

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
    final allComments = await _service.getComments(widget.studentId);
    final recentComments = allComments.where((c) {
      final date = DateTime.parse(c['created_at'] as String);
      return date.isAfter(sevenDaysAgo);
    }).toList();

    setState(() {
      _weekAbsences = absences;
      _weekRetards = retards;
      _weekComments = recentComments;
      _isLoading = false;
    });
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
            Text(
              'Alertes - ${widget.studentName}',
              style: TextStyle(
                color: AppTheme.nightBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.violet))
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  // ─── ABSENCES ────────────────────
                  _buildSectionTitle('Absences (7 jours)', Icons.cancel, Colors.red),
                  _buildAttendanceList(_weekAbsences, 'absent'),

                  // ─── RETARDS ─────────────────────
                  _buildSectionTitle('Retards (7 jours)', Icons.access_time, Colors.orange),
                  _buildAttendanceList(_weekRetards, 'late'),

                  // ─── COMMENTAIRES ────────────────
                  _buildSectionTitle('Commentaires (7 jours)', Icons.chat, AppTheme.violet),
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
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.nightBlue,
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
                Text(
                  'Aucun ${status == 'absent' ? 'absence' : 'retard'} cette semaine',
                  style: TextStyle(color: Colors.grey.shade500),
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
                        ),
                        Text(
                          '${date.day}/${date.month}/${date.year} à $time',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Text(
                  'Aucun commentaire cette semaine',
                  style: TextStyle(color: Colors.grey.shade500),
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

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.violet.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat, color: AppTheme.violet),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.nightBlue,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
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
}