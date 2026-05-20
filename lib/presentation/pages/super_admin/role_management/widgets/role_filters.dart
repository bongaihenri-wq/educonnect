// lib/presentation/pages/super_admin/role_management/widgets/role_filters.dart
import 'package:flutter/material.dart';

class RoleFilters extends StatelessWidget {
  final List<String> countries;
  final String? selectedCountry;
  final Function(String?) onCountryChanged;

  const RoleFilters({
    super.key,
    required this.countries,
    required this.selectedCountry,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrer par pays',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tous les pays'),
                selected: selectedCountry == null,
                onSelected: (selected) {
                  if (selected) onCountryChanged(null);
                },
              ),
              ...countries.map((country) {
                return ChoiceChip(
                  label: Text(_getCountryName(country)),
                  selected: selectedCountry == country,
                  selectedColor: const Color(0xFF6B4EFF).withOpacity(0.2),
                  onSelected: (selected) {
                    onCountryChanged(selected ? country : null);
                  },
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  String _getCountryName(String code) {
    switch (code) {
      case '+225': return '🇨🇮 Côte d\'Ivoire';
      case '+237': return '🇨🇲 Cameroun';
      case '+221': return '🇸🇳 Sénégal';
      case '+233': return '🇬🇭 Ghana';
      case '+226': return '🇧🇫 Burkina Faso';
      case '+241': return '🇬🇦 Gabon';
      default: return code;
    }
  }
}