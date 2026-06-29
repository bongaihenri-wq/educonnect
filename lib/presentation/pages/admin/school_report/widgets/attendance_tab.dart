// lib/presentation/pages/admin/school_report/widgets/attendance_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../blocs/school_report/school_report_bloc.dart';
import '../../../../blocs/school_report/school_report_state.dart';
import 'data_table.dart';
import 'status_badge.dart';

class AttendanceTab extends StatelessWidget {
  final SchoolReportBloc bloc;
  final VoidCallback onLoadMore;

  const AttendanceTab({
    super.key,
    required this.bloc,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchoolReportBloc, SchoolReportState>(
      builder: (context, state) {
        List<Map<String, dynamic>> data = [];
        bool hasMore = false;
        bool isLoadingMore = false;

        if (state is SchoolReportLoaded) {
          data = state.attendanceData;
          hasMore = state.hasMoreAttendance;
        } else if (state is SchoolReportLoadingMore) {
          data = state.attendanceData;
          isLoadingMore = state.isLoadingAttendance;
        } else if (state is SchoolReportExporting) {
          data = state.attendanceData;
        } else if (state is SchoolReportExportSuccess) {
          data = state.attendanceData;
        } else if (state is SchoolReportExportError) {
          data = state.attendanceData;
        } else if (state is SchoolReportLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SchoolReportError) {
          return Center(child: Text('Erreur: ${state.message}'));
        } else {
          return const SizedBox.shrink();
        }

        return ReportDataTable(
          data: data,
          hasMore: hasMore,
          isLoadingMore: isLoadingMore,
          onLoadMore: onLoadMore,
          columns: const [
            ReportColumn(key: 'date', label: 'Date', width: 55),
            ReportColumn(key: 'cours', label: 'Cours', width: 80),
            ReportColumn(key: 'horaire', label: 'Horaire', width: 80),
            ReportColumn(key: 'classe', label: 'Classe', width: 70),
            ReportColumn(key: 'eleve', label: 'Élève', width: 100),
            ReportColumn(key: 'enseignant', label: 'Enseignant', width: 100),
            ReportColumn(key: 'statut', label: 'Statut', width: 60, align: TextAlign.center),
          ],
          rowBuilder: (item) => _buildAttendanceRow(item),
        );
      },
    );
  }

  List<Widget> _buildAttendanceRow(Map<String, dynamic> item) {
    final dateStr = item['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final status = item['status'] as String?;
    final schedule = item['schedules'] as Map<String, dynamic>?;
    final subject = schedule?['subjects']?['name'] ?? '-';
    final startTime = _formatTime(schedule?['start_time']);
    final endTime = _formatTime(schedule?['end_time']);
    final classe = schedule?['classes'];
    final className = classe != null ? '${classe['level']} ${classe['name']}' : '-';

    final student = item['students'] as Map<String, dynamic>?;
    final studentName = student != null
        ? '${student['last_name'] ?? ''} ${student['first_name'] ?? ''}'.trim()
        : '-';

    final teacher = item['teachers'];
    final teacherName = teacher != null
        ? '${teacher['last_name'] ?? ''} ${teacher['first_name'] ?? ''}'.trim()
        : '-';

    return [
      Text(date != null ? '${date.day}/${date.month}' : '-', style: _cellStyle(11)),
      Text(subject, style: _cellStyle(11), maxLines: 1, overflow: TextOverflow.ellipsis),
      Text('$startTime-$endTime', style: _cellStyle(10)),
      Text(className, style: _cellStyle(10), maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(studentName, style: _cellStyle(11), maxLines: 2, overflow: TextOverflow.ellipsis),
      Text(teacherName, style: _cellStyle(11), maxLines: 2, overflow: TextOverflow.ellipsis),
      SizedBox(
        width: 60,
        child: StatusBadge(status: status),
      ),
    ];
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    final parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeStr;
  }

  TextStyle _cellStyle(double fontSize) {
    return TextStyle(fontSize: fontSize, color: const Color(0xFF1A1A2E));
  }
}