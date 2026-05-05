// lib/presentation/pages/teacher/widgets/report/report_student_attendance_timeline.dart
import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';
import '/../../../data/repositories/report_repository.dart';

class ReportStudentAttendanceTimeline extends StatelessWidget {
  final AttendanceStats stats;

  const ReportStudentAttendanceTimeline({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── TITRE ─────────────────────────────
            Row(
              children: [
                Icon(Icons.history, size: 18, color: AppTheme.violet),
                const SizedBox(width: 8),
                Text(
                  'Historique des présences',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.nightBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── MINI STATS (Prés/Abs/Rtd) ─────────
            Row(
              children: [
                _buildMiniCard('Prés', '${stats.presentCount}', AppTheme.mint),
                const SizedBox(width: 8),
                _buildMiniCard('Abs', '${stats.absentCount}', AppTheme.coral),
                const SizedBox(width: 8),
                _buildMiniCard('Rtd', '${stats.lateCount}', AppTheme.sunshine),
              ],
            ),
            const SizedBox(height: 16),

            // ─── EN-TÊTE TABLEAU ─────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('Date', style: _headerStyle())),
                  Expanded(flex: 3, child: Text('Cours', style: _headerStyle())),
                  Expanded(flex: 3, child: Text('Horaire', style: _headerStyle())),
                  Expanded(flex: 2, child: Text('Statut', style: _headerStyle(), textAlign: TextAlign.center)),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ─── LISTE DES PRÉSENCES (TABLEAU) ───
            SizedBox(
              height: stats.dailyBreakdown.length > 5 ? 250 : null,
              child: ListView.builder(
                shrinkWrap: stats.dailyBreakdown.length <= 5,
                physics: stats.dailyBreakdown.length > 5 ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                itemCount: stats.dailyBreakdown.length,
                itemBuilder: (context, index) {
                  final day = stats.dailyBreakdown[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        // ✅ DATE : "23/04"
                        Expanded(
                          flex: 2,
                          child: Text(
                            day.date,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.nightBlue,
                            ),
                          ),
                        ),
                        // ✅ COURS : "Anglais"
                        Expanded(
                          flex: 3,
                          child: Text(
                            day.courseName ?? 'Cours',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.nightBlue,
                            ),
                          ),
                        ),
                        // ✅ HORAIRE : "08:25-09:20"
                        Expanded(
                          flex: 3,
                          child: Text(
                            day.timeRange ?? '--:--',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        // ✅ STATUT ABRÉGÉ : "Prés" / "Abs" / "Rtd"
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: day.status!.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusLabel(day.status!),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: day.status!.color,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle() {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppTheme.violet,
    );
  }

  // ✅ ABRÉVIATIONS : Prés / Abs / Rtd
  String _getStatusLabel(AttendanceDayStatus status) {
    switch (status) {
      case AttendanceDayStatus.present: return 'Prés';
      case AttendanceDayStatus.absent: return 'Abs';
      case AttendanceDayStatus.late: return 'Rtd';
    }
  }

  Widget _buildMiniCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}