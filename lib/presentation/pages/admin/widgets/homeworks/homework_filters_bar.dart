// lib/presentation/pages/admin/widgets/homeworks/homework_filters_bar.dart
import 'package:flutter/material.dart';
import '/../../../config/theme.dart';

class HomeworkFiltersBar extends StatelessWidget {
  final String selectedFilter;
  final String selectedType;
  final String searchQuery;
  final List<Map<String, dynamic>> filters;
  final List<Map<String, dynamic>> types;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSearchChanged;

  const HomeworkFiltersBar({
    super.key,
    required this.selectedFilter,
    required this.selectedType,
    required this.searchQuery,
    required this.filters,
    required this.types,
    required this.onFilterChanged,
    required this.onTypeChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher un devoir...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        
        // Filtres statut
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: filters.map((filter) {
              final isSelected = selectedFilter == filter['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(filter['icon'] as IconData, size: 16),
                      const SizedBox(width: 4),
                      Text(filter['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.violet,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  onSelected: (selected) {
                    if (selected) onFilterChanged(filter['value'] as String);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Filtre type
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            value: selectedType,
            decoration: InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: types.map((type) {
              return DropdownMenuItem(
                value: type['value'] as String,
                child: Text(type['label'] as String),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
          ),
        ),
        
        const SizedBox(height: 8),
      ],
    );
  }
}