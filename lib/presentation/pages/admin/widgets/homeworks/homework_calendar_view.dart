// lib/presentation/pages/admin/widgets/homeworks/homework_calendar_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../homework_card.dart';

class HomeworkCalendarView extends StatefulWidget {
  final List<Map<String, dynamic>> homeworks;
  final Function(Map<String, dynamic>) onTap;
  final Function(Map<String, dynamic>) onToggleComplete;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;
  final String schoolYearStart;

  const HomeworkCalendarView({
    super.key,
    required this.homeworks,
    required this.onTap,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    this.schoolYearStart = '2025-09-01',
  });

  @override
  State<HomeworkCalendarView> createState() => _HomeworkCalendarViewState();
}

class _HomeworkCalendarViewState extends State<HomeworkCalendarView> {
  String _viewMode = 'trimestre';
  int _selectedTrimestre = 1;
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedWeek = DateTime.now();

  late final List<Map<String, dynamic>> _trimestres;

  @override
  void initState() {
    super.initState();
    final start = DateTime.parse(widget.schoolYearStart);
    _trimestres = [
      {
        'label': 'T1',
        'name': 'Trimestre 1',
        'start': start,
        'end': DateTime(start.year, 12, 20),
      },
      {
        'label': 'T2',
        'name': 'Trimestre 2',
        'start': DateTime(start.year + 1, 1, 5),
        'end': DateTime(start.year + 1, 3, 31),
      },
      {
        'label': 'T3',
        'name': 'Trimestre 3',
        'start': DateTime(start.year + 1, 4, 10),
        'end': DateTime(start.year + 1, 6, 30),
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredHomeworks {
    switch (_viewMode) {
      case 'trimestre':
        final t = _trimestres[_selectedTrimestre - 1];
        return widget.homeworks.where((h) {
          try {
            final date = DateTime.parse(h['due_date'].toString());
            return date.isAfter(t['start'].subtract(const Duration(days: 1))) &&
                   date.isBefore(t['end'].add(const Duration(days: 1)));
          } catch (e) {
            return false;
          }
        }).toList();
      
      case 'mois':
        return widget.homeworks.where((h) {
          try {
            final date = DateTime.parse(h['due_date'].toString());
            return date.year == _selectedMonth.year && date.month == _selectedMonth.month;
          } catch (e) {
            return false;
          }
        }).toList();
      
      case 'semaine':
        final weekStart = _selectedWeek.subtract(Duration(days: _selectedWeek.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return widget.homeworks.where((h) {
          try {
            final date = DateTime.parse(h['due_date'].toString());
            return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                   date.isBefore(weekEnd.add(const Duration(days: 1)));
          } catch (e) {
            return false;
          }
        }).toList();
      
      default:
        return widget.homeworks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildViewSelector(),
        const SizedBox(height: 8),
        _buildPeriodSelector(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_filteredHomeworks.length} devoir${_filteredHomeworks.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredHomeworks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun devoir pour cette période',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredHomeworks.length,
                  itemBuilder: (context, index) => HomeworkCard(
                    homework: _filteredHomeworks[index],
                    onTap: () => widget.onTap(_filteredHomeworks[index]),
                    onToggleComplete: () => widget.onToggleComplete(_filteredHomeworks[index]),
                    onEdit: () => widget.onEdit(_filteredHomeworks[index]),
                    onDelete: () => widget.onDelete(_filteredHomeworks[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildViewSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'trimestre', label: Text('Trimestre', style: TextStyle(fontSize: 11))),
          ButtonSegment(value: 'mois', label: Text('Mois', style: TextStyle(fontSize: 11))),
          ButtonSegment(value: 'semaine', label: Text('Semaine', style: TextStyle(fontSize: 11))),
        ],
        selected: {_viewMode},
        onSelectionChanged: (set) {
          setState(() => _viewMode = set.first);
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    switch (_viewMode) {
      case 'trimestre':
        return _buildTrimestreSelector();
      case 'mois':
        return _buildMoisSelector();
      case 'semaine':
        return _buildSemaineSelector();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTrimestreSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(3, (index) {
          final t = _trimestres[index];
          final isSelected = _selectedTrimestre == index + 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
              child: ChoiceChip(
                label: Center(
                  child: Text(
                    t['label'] as String,  // ← CAST explicite
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.purple.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.purple : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedTrimestre = index + 1);
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMoisSelector() {
    final months = List.generate(12, (i) {
      final month = DateTime(_selectedMonth.year, i + 1, 1);
      return {
        'label': DateFormat('MMM', 'fr_FR').format(month),
        'value': i + 1,
      };
    });

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: months.length,
        itemBuilder: (context, index) {
          final month = months[index];
          final isSelected = _selectedMonth.month == month['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                month['label'] as String,  // ← CAST explicite
                style: const TextStyle(fontSize: 11),
              ),
              selected: isSelected,
              selectedColor: Colors.purple.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? Colors.purple : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, month['value'] as int, 1);  // ← CAST explicite
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSemaineSelector() {
    final weekStart = _selectedWeek.subtract(Duration(days: _selectedWeek.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () => setState(() => _selectedWeek = _selectedWeek.subtract(const Duration(days: 7))),
          ),
          Expanded(
            child: Text(
              '${DateFormat('dd/MM', 'fr_FR').format(weekStart)} - ${DateFormat('dd/MM/yyyy', 'fr_FR').format(weekEnd)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: () => setState(() => _selectedWeek = _selectedWeek.add(const Duration(days: 7))),
          ),
        ],
      ),
    );
  }
}