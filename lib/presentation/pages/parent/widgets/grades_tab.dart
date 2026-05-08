// lib/presentation/pages/parent/widgets/grades_tab.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'common_widgets.dart';

class GradesTab extends StatefulWidget {
  final List<Map<String, dynamic>> grades;
  final Map<String, dynamic> stats;

  const GradesTab({
    super.key,
    required this.grades,
    required this.stats,
  });

  @override
  State<GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<GradesTab> {
  String _selectedDateFilter = 'Tout';
  String _selectedTypeFilter = 'Tout';
  String _selectedSubjectFilter = 'Tout';
  List<Map<String, dynamic>> _filteredGrades = [];

  @override
  void initState() {
    super.initState();
    _filteredGrades = widget.grades;
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(widget.grades);

    // Filtre par date (simplifié : 7 jours, 30 jours, tout)
    if (_selectedDateFilter == '7 jours') {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      filtered = filtered.where((g) {
        final date = DateTime.parse(g['date'] as String);
        return date.isAfter(sevenDaysAgo);
      }).toList();
    } else if (_selectedDateFilter == '30 jours') {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      filtered = filtered.where((g) {
        final date = DateTime.parse(g['date'] as String);
        return date.isAfter(thirtyDaysAgo);
      }).toList();
    }

    // Filtre par type
    if (_selectedTypeFilter != 'Tout') {
      filtered = filtered.where((g) => g['type'] == _selectedTypeFilter).toList();
    }

    // Filtre par matière
    if (_selectedSubjectFilter != 'Tout') {
      filtered = filtered.where((g) {
        final subject = g['subjects']?['name'] as String?;
        return subject == _selectedSubjectFilter;
      }).toList();
    }

    setState(() {
      _filteredGrades = filtered;
    });
  }

  List<String> _getAvailableTypes() {
    final types = widget.grades
        .map((g) => g['type'] as String?)
        .where((t) => t != null)
        .toSet()
        .cast<String>()
        .toList();
    return ['Tout', ...types];
  }

  List<String> _getAvailableSubjects() {
    final subjects = widget.grades
        .map((g) => g['subjects']?['name'] as String?)
        .where((s) => s != null)
        .toSet()
        .cast<String>()
        .toList();
    return ['Tout', ...subjects];
  }

  @override
  Widget build(BuildContext context) {
    final average = widget.stats['average'] != null && (widget.stats['average'] as double) > 0
        ? (widget.stats['average'] as double).toStringAsFixed(1)
        : '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── TITRE ─────────────────────────
          CommonWidgets.buildSectionTitle('Relevé de notes'),
          const SizedBox(height: 12),

          // ─── MOYENNE GÉNÉRALE ──────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Moyenne générale',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  '$average/20',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── FILTRES ─────────────────────────
          _buildFilters(),

          const SizedBox(height: 20),

          // ─── TABLEAU DES NOTES ─────────────
          if (_filteredGrades.isEmpty)
            CommonWidgets.buildEmptyState('Aucune note pour ces filtres')
          else
            _buildGradesTable(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        // Ligne 1 : Date + Type
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                value: _selectedDateFilter,
                items: const ['Tout', '7 jours', '30 jours'],
                label: 'Période',
                onChanged: (val) {
                  setState(() => _selectedDateFilter = val);
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                value: _selectedTypeFilter,
                items: _getAvailableTypes(),
                label: 'Type',
                onChanged: (val) {
                  setState(() => _selectedTypeFilter = val);
                  _applyFilters();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ligne 2 : Matière
        _buildDropdown(
          value: _selectedSubjectFilter,
          items: _getAvailableSubjects(),
          label: 'Matière',
          onChanged: (val) {
            setState(() => _selectedSubjectFilter = val);
            _applyFilters();
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.violet.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.violet),
          hint: Text(label, style: TextStyle(color: Colors.grey.shade500)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.nightBlue,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }

  Widget _buildGradesTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ─── EN-TÊTE ─────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('Date', style: _headerStyle())),
                  Expanded(flex: 2, child: Text('Type', style: _headerStyle())),
                  Expanded(flex: 3, child: Text('Matière', style: _headerStyle())),
                  Expanded(flex: 1, child: Text('Coef', style: _headerStyle(), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('Note', style: _headerStyle(), textAlign: TextAlign.center)),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ─── LIGNES ──────────────────────
            ..._filteredGrades.map((g) => _buildGradeRow(g)),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeRow(Map<String, dynamic> grade) {
    final value = (grade['score'] as num).toDouble();
    final maxValue = (grade['max_score'] as num?)?.toDouble() ?? 20.0;
    final subject = grade['subjects']?['name'] ?? 'Matière';
    final type = grade['type'] ?? 'Note';
    final coef = (grade['coefficient'] as num?)?.toInt() ?? 1;
    final date = DateTime.parse(grade['date'] as String);
    final noteSur20 = maxValue > 0 ? (value / maxValue) * 20 : 0.0;

    Color color;
    if (noteSur20 >= 14) color = Colors.green;
    else if (noteSur20 >= 10) color = Colors.orange;
    else color = Colors.red;

    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Date
          Expanded(
            flex: 2,
            child: Text(
              dateStr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.nightBlue,
              ),
            ),
          ),
          // Type
          Expanded(
            flex: 2,
            child: Text(
              type,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          // Matière
          Expanded(
            flex: 3,
            child: Text(
              subject,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.nightBlue,
              ),
            ),
          ),
          // Coef
          Expanded(
            flex: 1,
            child: Text(
              '$coef',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.nightBlue,
              ),
            ),
          ),
          // Note /20
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${noteSur20.toStringAsFixed(1)}/20',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
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
}