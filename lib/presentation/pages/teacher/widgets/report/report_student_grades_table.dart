// lib/presentation/pages/teacher/widgets/report/report_student_grades_table.dart
// NOUVEAU FICHIER ou modification

import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';
import '/../../../data/repositories/report_repository.dart';

class ReportStudentGradesTable extends StatefulWidget {
  final GradeStats stats;

  const ReportStudentGradesTable({super.key, required this.stats});

  @override
  State<ReportStudentGradesTable> createState() => _ReportStudentGradesTableState();
}

class _ReportStudentGradesTableState extends State<ReportStudentGradesTable> {
  String? _filterType;
  String? _filterDate;

  @override
  Widget build(BuildContext context) {
    // ✅ MÊME PRÉSENTATION que ReportClassGradesStats
    final gradeData = widget.stats.grades.map((g) => {
      'type': g.type,
      'date': '${g.date.day.toString().padLeft(2, '0')}/${g.date.month.toString().padLeft(2, '0')}',
      'score': g.value,
      'maxScore': g.outOf,
      'grade': '${g.value.toStringAsFixed(1)}/${g.outOf.toInt()}',
      'percentage': g.outOf > 0 ? (g.value / g.outOf * 100).toStringAsFixed(1) : '0.0',
      'coef': '${g.coefficient}',
    }).toList();

    if (gradeData.isEmpty) {
      return _buildEmptyState('Aucune note pour cette période');
    }

    final types = gradeData.map((g) => g['type'] as String).toSet().toList();
    final dates = gradeData.map((g) => g['date'] as String).toSet().toList();

    var filteredData = gradeData;
    if (_filterType != null) filteredData = filteredData.where((g) => g['type'] == _filterType).toList();
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
            // Header avec moyenne
            Row(
              children: [
                Icon(Icons.school_outlined, size: 18, color: AppTheme.violet),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Notes — Moy: ${widget.stats.average.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.nightBlue,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.violetPale,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.stats.grades.length} notes',
                    style: TextStyle(fontSize: 11, color: AppTheme.violet),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ✅ FILTRES (même que classe)
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
                    label: _filterDate ?? 'Date',
                    options: dates,
                    selected: _filterDate,
                    onSelected: (val) => setState(() => _filterDate = val),
                  ),
                  if (_filterType != null || _filterDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppTheme.coral),
                      onPressed: () => setState(() {
                        _filterType = null;
                        _filterDate = null;
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ✅ TABLEAU : Type, Date, Note, Coef
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 350,
                child: Column(
                  children: [
                    // En-tête
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.violetPale,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 80, child: Text('Type', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.violet), textAlign: TextAlign.left)),
                          SizedBox(width: 60, child: Text('Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.violet), textAlign: TextAlign.center)),
                          SizedBox(width: 100, child: Text('Note', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.violet), textAlign: TextAlign.center)),
                          SizedBox(width: 30, child: Text('Coef', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.violet), textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                    
                    // Données
                    SizedBox(
                      height: 300,
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
                                SizedBox(width: 80, child: Text(g['type'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.left)),
                                SizedBox(width: 60, child: Text(g['date'] as String, style: TextStyle(fontSize: 10, color: AppTheme.nightBlue), textAlign: TextAlign.center)),
                                SizedBox(width: 100, child: _buildGrade(g['grade'] as String)),
                                SizedBox(width: 30, child: Text(g['coef'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), textAlign: TextAlign.right)),
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
    final max = double.tryParse(grade.split('/')[1]) ?? 20;
    final pct = max > 0 ? (value / max) * 100 : 0;
    
    Color color;
    if (pct >= 80) color = AppTheme.mint;      // > 16/20
    else if (pct >= 60) color = AppTheme.teal;  // 12-16/20
    else if (pct >= 50) color = AppTheme.sunshine; // 10-12/20
    else color = AppTheme.coral;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  Widget _buildEmptyState(String message) {
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
                message,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}