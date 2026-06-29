// lib/presentation/pages/admin/school_report/widgets/report_filters.dart
import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';
import '../../widgets/period_selector.dart';

class ReportFilters extends StatelessWidget {
  final List<Map<String, dynamic>> academicPeriods;
  final Map<String, dynamic>? selectedPeriod;
  final bool loadingPeriods;
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> teachers;
  final String? selectedClassId;
  final String? selectedSubjectId;
  final String? selectedTeacherId;
  final String? selectedStudentId;
  final Function(Map<String, dynamic>?) onPeriodChanged;
  final Function(String?) onClassChanged;
  final Function(String?) onSubjectChanged;
  final Function(String?) onTeacherChanged;
  final Function(String?) onStudentChanged;

  const ReportFilters({
    super.key,
    required this.academicPeriods,
    required this.selectedPeriod,
    required this.loadingPeriods,
    required this.classes,
    required this.subjects,
    required this.teachers,
    required this.selectedClassId,
    required this.selectedSubjectId,
    required this.selectedTeacherId,
    required this.selectedStudentId,
    required this.onPeriodChanged,
    required this.onClassChanged,
    required this.onSubjectChanged,
    required this.onTeacherChanged,
    required this.onStudentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ PeriodSelector remis ici comme avant
          if (academicPeriods.isNotEmpty)
            PeriodSelector(
              periods: academicPeriods,
              selectedPeriod: selectedPeriod,
              onPeriodChanged: onPeriodChanged,
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildClassDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildSubjectDropdown()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTeacherDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildStudentDropdown()),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return _buildDropdown(
      value: selectedClassId,
      hint: 'Toutes les classes',
      items: [
        const DropdownMenuItem(value: null, child: Text('Toutes les classes')),
        ...classes.map((c) => DropdownMenuItem(
              value: c['id'] as String,
              child: Text('${c['level']} ${c['name']}',
                  overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: onClassChanged,
    );
  }

  Widget _buildSubjectDropdown() {
    return _buildDropdown(
      value: selectedSubjectId,
      hint: 'Toutes les matières',
      items: [
        const DropdownMenuItem(value: null, child: Text('Toutes les matières')),
        ...subjects.map((s) => DropdownMenuItem(
              value: s['id'] as String,
              child: Text(s['name'] as String,
                  overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: onSubjectChanged,
    );
  }

  Widget _buildTeacherDropdown() {
    return _buildDropdown(
      value: selectedTeacherId,
      hint: 'Tous les enseignants',
      items: [
        const DropdownMenuItem(value: null, child: Text('Tous les enseignants')),
        ...teachers.map((t) => DropdownMenuItem(
              value: t['id'] as String,
              child: Text('${t['last_name']} ${t['first_name']}',
                  overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: onTeacherChanged,
    );
  }

  Widget _buildStudentDropdown() {
    return _buildDropdown(
      value: selectedStudentId,
      hint: 'Tous les élèves',
      items: const [
        DropdownMenuItem(value: null, child: Text('Tous les élèves')),
      ],
      onChanged: onStudentChanged,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.violet.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          icon: Icon(Icons.arrow_drop_down,
              color: AppTheme.violet, size: 20),
          style: TextStyle(fontSize: 13, color: AppTheme.nightBlue),
          items: items,
          onChanged: (val) => onChanged(val),
        ),
      ),
    );
  }
}