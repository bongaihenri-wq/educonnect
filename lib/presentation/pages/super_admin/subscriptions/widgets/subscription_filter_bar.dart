// lib/presentation/pages/super_admin/subscriptions/widgets/subscription_filter_bar.dart
import 'package:flutter/material.dart';

class SubscriptionFilterBar extends StatelessWidget {
  final List<Map<String, dynamic>> schools;
  final String? selectedSchool;
  final String? selectedCountry;
  final String? selectedStatus;
  final String searchQuery;
  final Function({
    String? school,
    String? country,
    String? status,
    String? search,
  }) onFilterChanged;

  const SubscriptionFilterBar({
    super.key,
    required this.schools,
    this.selectedSchool,
    this.selectedCountry,
    this.selectedStatus,
    required this.searchQuery,
    required this.onFilterChanged,
  });

  // ✅ CORRIGÉ : country → country_code
  List<String> get _countries {
    final countries = schools
        .map((s) => s['country_code'] as String?)
        .where((c) => c != null && c.isNotEmpty)
        .toSet()
        .toList();
    return List<String>.from(countries)..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
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
          const Row(
            children: [
              Icon(Icons.filter_list, color: Color(0xFF6B4EFF), size: 20),
              SizedBox(width: 8),
              Text(
                'Filtres',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ CORRIGÉ : Recherche sans controller fixe
          TextField(
            decoration: InputDecoration(
              hintText: '🔍 Rechercher un parent...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B4EFF)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) {
              Future.delayed(const Duration(milliseconds: 500), () {
                onFilterChanged(search: value);
              });
            },
          ),
          const SizedBox(height: 12),

          // ✅ CORRIGÉ : Wrap au lieu de Row pour éviter overflow
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.28,
                child: _buildDropdown(
                  hint: '🏫 École',
                  value: selectedSchool,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Toutes', overflow: TextOverflow.ellipsis),
                    ),
                    ...schools.map((school) => DropdownMenuItem(
                      value: school['id'] as String,
                      child: Text(
                        school['name'] as String? ?? 'Sans nom',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                  ],
                  onChanged: (value) => onFilterChanged(school: value),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.28,
                child: _buildDropdown(
                  hint: '🌍 Pays',
                  value: selectedCountry,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tous', overflow: TextOverflow.ellipsis),
                    ),
                    ..._countries.map((country) => DropdownMenuItem(
                      value: country,
                      child: Text(country, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (value) => onFilterChanged(country: value),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.28,
                child: _buildDropdown(
                  hint: '📊 Statut',
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Tous', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'active',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF00C853), size: 14),
                          SizedBox(width: 4),
                          Text('Actif', overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'trial',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Color(0xFFFFB300), size: 14),
                          SizedBox(width: 4),
                          Text('Trial', overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'expired',
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Color(0xFFFF1744), size: 14),
                          SizedBox(width: 4),
                          Text('Expiré', overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) => onFilterChanged(status: value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B4EFF), size: 20),
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
            color: Color(0xFF2D3142),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}