// lib/presentation/pages/teacher/widgets/report/report_class_grades_stats.dart
import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';
import '/../../../data/repositories/report_repository.dart';

class ReportClassGradesStats extends StatefulWidget {
  final ClassGradeStats stats;

  const ReportClassGradesStats({super.key, required this.stats});

  @override
  State<ReportClassGradesStats> createState() => _ReportClassGradesStatsState();
}

class _ReportClassGradesStatsState extends State<ReportClassGradesStats> {
  String? _filterType;
  String? _filterStudent;
  String? _filterDate;

  @override
  Widget build(BuildContext context) {
    // ✅ DONNÉES RÉELLES : Utiliser le vrai nom de l'élève depuis GradeInfo.studentName
    final gradeData = widget.stats.grades.map((g) => {
      'type': g.type,
      'date': '${g.date.day.toString().padLeft(2, '0')}/${g.date.month.toString().padLeft(2, '0')}',
      'student': g.studentName, // ✅ VRAI NOM — remplace 'Élève'
      'grade': '${g.value.toStringAsFixed(1)}/${g.outOf.toInt()}',
      'coef': '${g.coefficient}',
    }).toList();

    if (gradeData.isEmpty) {
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
                Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Aucune note pour cette période',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final types = gradeData.map((g) => g['type']!).toSet().toList();
    final students = gradeData.map((g) => g['student']!).toSet().toList();
    final dates = gradeData.map((g) => g['date']!).toSet().toList();

    var filteredData = gradeData;
    if (_filterType != null) filteredData = filteredData.where((g) => g['type'] == _filterType).toList();
    if (_filterStudent != null) filteredData = filteredData.where((g) => g['student'] == _filterStudent).toList();
    if (_filterDate != null) filteredData = filteredData.where((g) => g['date'] == _filterDate).toList();

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
                Icon(Icons.school_outlined, size: 18, color: AppTheme.violet),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.nightBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: _filterType ?? 'Type',
                    options: types,
                    selected: _filterType,
                    onSelected: (val) => setState(() => _filterType = val),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _filterStudent ?? 'Élève',
                    options: students,
                    selected: _filterStudent,
                    onSelected: (val) => setState(() => _filterStudent = val),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _filterDate ?? 'Date',
                    options: dates,
                    selected: _filterDate,
                    onSelected: (val) => setState(() => _filterDate = val),
                  ),
                  if (_filterType != null || _filterStudent != null || _filterDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppTheme.coral),
                      onPressed: () => setState(() {
                        _filterType = null;
                        _filterStudent = null;
                        _filterDate = null;
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 400,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.violetPale,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 70, child: Text('Type', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.violet), textAlign: TextAlign.left)),
                          SizedBox(width: 50, child: Text('Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.violet), textAlign: TextAlign.center)),
                          SizedBox(width: 100, child: Text('Élève', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.violet), textAlign: TextAlign.left)),
                          SizedBox(width: 70, child: Text('Note', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.violet), textAlign: TextAlign.center)),
                          SizedBox(width: 40, child: Text('Coef', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.violet), textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                    
                    SizedBox(
                      height: 400,
                      child: ListView.builder(
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          final g = filteredData[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 70, child: Text(g['type']!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.left)),
                                SizedBox(width: 50, child: Text(g['date']!, style: TextStyle(fontSize: 10, color: AppTheme.nightBlue), textAlign: TextAlign.center)),
                                // ✅ VRAI NOM DE L'ÉLÈVE
                                SizedBox(width: 100, child: Text(g['student']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.nightBlue), textAlign: TextAlign.left, overflow: TextOverflow.ellipsis)),
                                SizedBox(width: 70, child: _buildGrade(g['grade']!)),
                                SizedBox(width: 40, child: Text(g['coef']!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), textAlign: TextAlign.right)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required List<String> options,
    required String? selected,
    required Function(String?) onSelected,
  }) {
    return PopupMenuButton<String?>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected != null ? AppTheme.violetPale : Colors.grey.shade100,
          border: Border.all(color: selected != null ? AppTheme.violet : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected != null ? AppTheme.violet : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: selected != null ? AppTheme.violet : Colors.grey.shade400),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('Tous')),
        ...options.map((o) => PopupMenuItem(value: o, child: Text(o))),
      ],
      onSelected: onSelected,
    );
  }

  Widget _buildGrade(String grade) {
    final value = double.tryParse(grade.split('/')[0]) ?? 0;
    Color color;
    if (value >= 15) color = AppTheme.mint;
    else if (value >= 12) color = AppTheme.teal;
    else if (value >= 10) color = AppTheme.sunshine;
    else color = AppTheme.coral;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        grade,
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