// lib/presentation/pages/parent/widgets/grades_tab.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../admin/widgets/period_selector.dart';
import 'common_widgets.dart';

class GradesTab extends StatefulWidget {
  final List<Map<String, dynamic>> grades;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> periods;
  final Map<String, dynamic>? selectedPeriod;
  final ValueChanged<Map<String, dynamic>?> onPeriodChanged;

  const GradesTab({
    super.key,
    required this.grades,
    required this.stats,
    this.periods = const [],
    this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  State<GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<GradesTab> {
  String _selectedTypeFilter = 'Tout';
  String _selectedSubjectFilter = 'Tout';

  // ─── VÉRIFICATIONS PÉRIODE ─────────────────────────

  bool _isTrimesterPeriod(Map<String, dynamic>? period) {
    if (period == null) return false;
    final id = period['id'] as String?;
    return id != null && !id.startsWith('dynamic_');
  }

  String get _trimesterName {
    if (_isTrimesterPeriod(widget.selectedPeriod)) {
      return widget.selectedPeriod!['name'] as String? ?? 'Trimestre';
    }
    return 'Trimestre';
  }

  String? get _trimesterDateRange {
    final period = widget.selectedPeriod;
    if (period == null) return null;
    final start = period['start_date'] as String?;
    final end = period['end_date'] as String?;
    if (start == null || end == null) return null;
    return '${_formatShortDate(start)} → ${_formatShortDate(end)}';
  }

  // ─── FILTRAGE DES NOTES ─────────────────────────

  List<Map<String, dynamic>> get _periodFilteredGrades {
    if (widget.selectedPeriod == null) return widget.grades;

    final startDate = widget.selectedPeriod!['start_date'] as String?;
    final endDate = widget.selectedPeriod!['end_date'] as String?;

    if (startDate == null || endDate == null) return widget.grades;

    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);

    return widget.grades.where((g) {
      final date = DateTime.parse(g['date'] as String);
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  List<Map<String, dynamic>> get _fullyFilteredGrades {
    var filtered = _periodFilteredGrades;

    if (_selectedTypeFilter != 'Tout') {
      filtered = filtered.where((g) => g['type'] == _selectedTypeFilter).toList();
    }

    if (_selectedSubjectFilter != 'Tout') {
      filtered = filtered.where((g) {
        final subject = g['subjects']?['name'] as String?;
        return subject == _selectedSubjectFilter;
      }).toList();
    }

    return filtered;
  }

  // ─── MOYENNES ─────────────────────────

  double get _trimesterAverage {
    final grades = _periodFilteredGrades;
    if (grades.isEmpty) return 0.0;

    double weightedSum = 0.0;
    int totalCoef = 0;

    for (final g in grades) {
      final score = (g['score'] as num).toDouble();
      final maxScore = (g['max_score'] as num?)?.toDouble() ?? 20.0;
      final coef = (g['coefficient'] as num?)?.toInt() ?? 1;
      final normalized = maxScore > 0 ? (score / maxScore) * 20 : 0.0;
      weightedSum += normalized * coef;
      totalCoef += coef;
    }

    return totalCoef > 0 ? weightedSum / totalCoef : 0.0;
  }

  double get _filteredAverage {
    final grades = _fullyFilteredGrades;
    if (grades.isEmpty) return 0.0;

    double weightedSum = 0.0;
    int totalCoef = 0;

    for (final g in grades) {
      final score = (g['score'] as num).toDouble();
      final maxScore = (g['max_score'] as num?)?.toDouble() ?? 20.0;
      final coef = (g['coefficient'] as num?)?.toInt() ?? 1;
      final normalized = maxScore > 0 ? (score / maxScore) * 20 : 0.0;
      weightedSum += normalized * coef;
      totalCoef += coef;
    }

    return totalCoef > 0 ? weightedSum / totalCoef : 0.0;
  }

  // ─── LISTES POUR DROPDOWNS ─────────────────────────

  List<String> get _availableTypes {
    final types = _periodFilteredGrades
        .map((g) => g['type'] as String?)
        .where((t) => t != null)
        .toSet()
        .cast<String>()
        .toList();
    return ['Tout', ...types];
  }

  List<String> get _availableSubjects {
    final subjects = _periodFilteredGrades
        .map((g) => g['subjects']?['name'] as String?)
        .where((s) => s != null)
        .toSet()
        .cast<String>()
        .toList();
    return ['Tout', ...subjects];
  }

  // ─── LIFECYCLE ─────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedTypeFilter = 'Tout';
    _selectedSubjectFilter = 'Tout';
  }

  @override
  void didUpdateWidget(GradesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod?['id'] != widget.selectedPeriod?['id']) {
      setState(() {
        _selectedTypeFilter = 'Tout';
        _selectedSubjectFilter = 'Tout';
      });
    }
  }

  // ─── BUILD PRINCIPAL ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final trimesterAvg = _trimesterAverage;
    final filteredAvg = _filteredAverage;
    final filteredGrades = _fullyFilteredGrades;

    return Column(
      children: [
        // ═══════════════════════════════════════
        // SECTION FIGÉE : Moyennes + Filtres
        // ═══════════════════════════════════════
        Container(
          color: AppTheme.bisLight,
          child: Column(
            children: [
              // ─── MOYENNE TRIMESTRE ───
              _buildTrimesterAverageCard(trimesterAvg),

              const SizedBox(height: 12),

              // ─── FILTRES ───
              _buildFilters(),

              const SizedBox(height: 8),

              // ─── MOYENNE FILTRÉE ───
              if (_selectedTypeFilter != 'Tout' || _selectedSubjectFilter != 'Tout')
                _buildFilteredAverageCard(filteredAvg),

              const SizedBox(height: 8),
            ],
          ),
        ),

        // ═══════════════════════════════════════
        // SECTION SCROLLABLE : Tableau des notes
        // ═══════════════════════════════════════
        Expanded(
          child: filteredGrades.isEmpty
              ? _buildEmptyState()
              : _buildGradesList(filteredGrades),
        ),
      ],
    );
  }

  // ─── WIDGET : Moyenne Trimestre ─────────────────────────

  Widget _buildTrimesterAverageCard(double average) {
    final hasData = average > 0;
    final displayAvg = hasData ? average.toStringAsFixed(1) : '-';
    final trimesterLabel = _trimesterName;
    final dateRange = _trimesterDateRange;

    Color avgColor;
    if (!hasData) {
      avgColor = Colors.grey;
    } else if (average >= 14) {
      avgColor = Colors.green;
    } else if (average >= 10) {
      avgColor = Colors.orange;
    } else {
      avgColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Moyenne $trimesterLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (dateRange != null)
                    Text(
                      dateRange,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$displayAvg/20',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (hasData) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: average / 20,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  avgColor.withOpacity(0.9),
                ),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── WIDGET : Moyenne Filtrée ─────────────────────────

  Widget _buildFilteredAverageCard(double average) {
    final hasData = average > 0;
    final displayAvg = hasData ? average.toStringAsFixed(1) : '-';

    String filterLabel = '';
    if (_selectedTypeFilter != 'Tout' && _selectedSubjectFilter != 'Tout') {
      filterLabel = '$_selectedTypeFilter · $_selectedSubjectFilter';
    } else if (_selectedTypeFilter != 'Tout') {
      filterLabel = _selectedTypeFilter;
    } else if (_selectedSubjectFilter != 'Tout') {
      filterLabel = _selectedSubjectFilter;
    }

    Color avgColor;
    if (!hasData) {
      avgColor = Colors.grey;
    } else if (average >= 14) {
      avgColor = Colors.green;
    } else if (average >= 10) {
      avgColor = Colors.orange;
    } else {
      avgColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.violet.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avgColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Moyenne filtrée',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  filterLabel.isNotEmpty ? filterLabel : 'Tous les éléments',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.nightBlue,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '$displayAvg/20',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: avgColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── WIDGET : Filtres ─────────────────────────

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Période (PeriodSelector existant)
          if (widget.periods.isNotEmpty)
            PeriodSelector(
              periods: widget.periods,
              selectedPeriod: widget.selectedPeriod,
              onPeriodChanged: (period) {
                widget.onPeriodChanged(period);
              },
            ),

          const SizedBox(height: 10),

          // Type + Matière
          Row(
            children: [
              Expanded(
                child: _buildCompactDropdown(
                  value: _selectedTypeFilter,
                  items: _availableTypes,
                  label: 'Type',
                  icon: Icons.assignment,
                  onChanged: (val) => setState(() => _selectedTypeFilter = val),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCompactDropdown(
                  value: _selectedSubjectFilter,
                  items: _availableSubjects,
                  label: 'Matière',
                  icon: Icons.book,
                  onChanged: (val) => setState(() => _selectedSubjectFilter = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.violet, size: 18),
          style: const TextStyle(fontSize: 13, color: AppTheme.nightBlue),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: AppTheme.violet.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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

  // ─── WIDGET : Liste des notes ─────────────────────────

  Widget _buildGradesList(List<Map<String, dynamic>> grades) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: grades.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTableHeader();
        }
        return _buildCompactGradeRow(grades[index - 1]);
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.violet.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _headerText('Date')),
          Expanded(flex: 2, child: _headerText('Type')),
          Expanded(flex: 3, child: _headerText('Matière')),
          Expanded(flex: 1, child: _headerText('Coef', center: true)),
          Expanded(flex: 2, child: _headerText('Note', center: true)),
        ],
      ),
    );
  }

  Widget _headerText(String text, {bool center = false}) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.violet,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildCompactGradeRow(Map<String, dynamic> grade) {
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
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dateStr,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              type,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              subject,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.nightBlue,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$coef',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${noteSur20.toStringAsFixed(1)}/20',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Aucune note pour cette période',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          if (_selectedTypeFilter != 'Tout' || _selectedSubjectFilter != 'Tout')
            Text(
              'Essayez de changer les filtres',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  // ─── HELPERS ─────────────────────────

  String _formatShortDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return isoDate;
    }
  }
}