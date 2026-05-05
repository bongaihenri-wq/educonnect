// lib/presentation/pages/teacher/widgets/report/report_class_attendance_stats.dart
import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';
import '/../../../data/repositories/report_repository.dart';

class ReportClassAttendanceStats extends StatelessWidget {
  final ClassAttendanceStats stats;

  const ReportClassAttendanceStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    // ✅ DONNÉES RÉELLES : Utiliser directement les données du repository
    final dailyData = stats.dailyAttendance;

    if (dailyData.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.calendar_month_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Aucune présence pour cette période',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 18, color: AppTheme.violet),
                const SizedBox(width: 8),
                Text(
                  'Présences',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.nightBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.violetPale,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.violet), textAlign: TextAlign.left)),
                  Expanded(child: Text('Prés', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mint), textAlign: TextAlign.center)),
                  Expanded(child: Text('Abs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.coral), textAlign: TextAlign.center)),
                  Expanded(child: Text('Ret', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.sunshine), textAlign: TextAlign.center)),
                ],
              ),
            ),
            
            SizedBox(
              height: 400,
              child: ListView.builder(
                itemCount: dailyData.length,
                itemBuilder: (context, index) {
                  final day = dailyData[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(day.date, style: TextStyle(fontSize: 12, color: AppTheme.nightBlue), textAlign: TextAlign.left)),
                        Expanded(child: _buildCount(day.present, AppTheme.mint)),
                        Expanded(child: _buildCount(day.absent, AppTheme.coral)),
                        Expanded(child: _buildCount(day.late, AppTheme.sunshine)),
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

  Widget _buildCount(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}