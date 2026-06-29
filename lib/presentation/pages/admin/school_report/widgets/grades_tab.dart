// lib/presentation/pages/admin/school_report/widgets/grades_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../blocs/school_report/school_report_bloc.dart';
import '../../../../blocs/school_report/school_report_state.dart';
import 'data_table.dart';
import 'grade_badge.dart';

class GradesTab extends StatelessWidget {
  final SchoolReportBloc bloc;
  final VoidCallback onLoadMore;

  const GradesTab({
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
          data = state.gradesData;
          hasMore = state.hasMoreGrades;
        } else if (state is SchoolReportLoadingMore) {
          data = state.gradesData;
          isLoadingMore = state.isLoadingGrades;
        } else if (state is SchoolReportExporting) {
          data = state.gradesData;
        } else if (state is SchoolReportExportSuccess) {
          data = state.gradesData;
        } else if (state is SchoolReportExportError) {
          data = state.gradesData;
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
            ReportColumn(key: 'classe', label: 'Classe', width: 70),
            ReportColumn(key: 'eleve', label: 'Élève', width: 100),
            ReportColumn(key: 'matiere', label: 'Matière', width: 80),
            ReportColumn(key: 'coef', label: 'Coef', width: 50, align: TextAlign.center),
            ReportColumn(key: 'note', label: 'Note', width: 70, align: TextAlign.center),
          ],
          rowBuilder: (item) => _buildGradeRow(item),
        );
      },
    );
  }

  List<Widget> _buildGradeRow(Map<String, dynamic> item) {
    final dateStr = item['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final student = item['students'] as Map<String, dynamic>?;
    final studentName = student != null
        ? '${student['last_name'] ?? ''} ${student['first_name'] ?? ''}'.trim()
        : '-';
    final classe = item['classes'];
    final className = classe != null ? '${classe['level']} ${classe['name']}' : '-';
    final subject = item['subjects']?['name'] ?? '-';
    final coef = (item['coefficient'] as num?)?.toInt() ?? 1;
    final score = (item['score'] as num?)?.toDouble() ?? 0;
    final maxScore = (item['max_score'] as num?)?.toDouble() ?? 20;
    final noteSur20 = maxScore > 0 ? (score / maxScore) * 20 : 0;

    return [
      Text(date != null ? '${date.day}/${date.month}' : '-', style: _cellStyle(11)),
      Text(className, style: _cellStyle(10), maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(studentName, style: _cellStyle(11), maxLines: 2, overflow: TextOverflow.ellipsis),
      Text(subject, style: _cellStyle(11), maxLines: 1, overflow: TextOverflow.ellipsis),
      Text('$coef', style: _cellStyle(11), textAlign: TextAlign.center),
      SizedBox(
        width: 70,
        child: GradeBadge(noteSur20: noteSur20.toDouble()), // ✅ CORRIGÉ ICI
      ),
    ];
  }

  TextStyle _cellStyle(double fontSize) {
    return TextStyle(fontSize: fontSize, color: const Color(0xFF1A1A2E));
  }
}