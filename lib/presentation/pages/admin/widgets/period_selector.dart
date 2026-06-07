// lib/presentation/pages/admin/widgets/period_selector.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class PeriodSelector extends StatefulWidget {
  final Function(String trimestre, int? mois) onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.onPeriodChanged,
  });

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  String _selectedTrimestre = 'T1';
  int? _selectedMois;

  final List<String> _trimestres = ['T1', 'T2', 'T3', 'Année'];
  final List<Map<String, dynamic>> _mois = [
    {'numero': 9, 'nom': 'Sept'},
    {'numero': 10, 'nom': 'Oct'},
    {'numero': 11, 'nom': 'Nov'},
    {'numero': 12, 'nom': 'Déc'},
    {'numero': 1, 'nom': 'Jan'},
    {'numero': 2, 'nom': 'Fév'},
    {'numero': 3, 'nom': 'Mar'},
    {'numero': 4, 'nom': 'Avr'},
    {'numero': 5, 'nom': 'Mai'},
    {'numero': 6, 'nom': 'Juin'},
    {'numero': 7, 'nom': 'Juil'},
    {'numero': 8, 'nom': 'Août'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Période',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.nightBlue,
            ),
          ),
          const SizedBox(height: 12),
          
          // Trimestres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _trimestres.map((t) {
                final isSelected = _selectedTrimestre == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: isSelected,
                    selectedColor: AppTheme.violet,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTrimestre = t;
                          _selectedMois = null;
                        });
                        widget.onPeriodChanged(t, null);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Mois (scrollable horizontal si trop long)
          const Text(
            'Mois (optionnel)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _mois.map((m) {
                final isSelected = _selectedMois == m['numero'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(m['nom']),
                    selected: isSelected,
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedMois = selected ? m['numero'] : null;
                      });
                      widget.onPeriodChanged(_selectedTrimestre, selected ? m['numero'] : null);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}