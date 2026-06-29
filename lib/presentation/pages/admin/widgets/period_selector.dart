// lib/presentation/pages/admin/widgets/period_selector.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class PeriodSelector extends StatefulWidget {
  final List<Map<String, dynamic>> periods;
  final Map<String, dynamic>? selectedPeriod;
  final ValueChanged<Map<String, dynamic>?> onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.periods,
    this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  @override
  Widget build(BuildContext context) {
    if (widget.periods.isEmpty) return const SizedBox.shrink();

    // ✅ Séparer dynamiques (id commence par "dynamic_") et académiques
    final dynamicPeriods = widget.periods.where((p) {
      final id = p['id'] as String?;
      return id != null && id.startsWith('dynamic_');
    }).toList();

    final academicPeriods = widget.periods.where((p) {
      final id = p['id'] as String?;
      return id == null || !id.startsWith('dynamic_');
    }).toList();

    final List<DropdownMenuItem<String>> items = [];

    // Section 1: Périodes rapides
    if (dynamicPeriods.isNotEmpty) {
      items.add(
        DropdownMenuItem<String>(
          value: '__header_dynamic__',
          enabled: false,
          child: Text(
            'Périodes rapides',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      for (final period in dynamicPeriods) {
        final name = period['name'] as String;
        items.add(
          DropdownMenuItem<String>(
            value: name,
            child: _buildDropdownItem(period, isDynamic: true),
          ),
        );
      }
    }

    // Séparateur
    if (dynamicPeriods.isNotEmpty && academicPeriods.isNotEmpty) {
      items.add(
        DropdownMenuItem<String>(
          value: '__separator__',
          enabled: false,
          child: Divider(height: 8, indent: 8, endIndent: 8, color: Colors.grey[200]),
        ),
      );
    }

    // Section 2: Année scolaire
    if (academicPeriods.isNotEmpty) {
      items.add(
        DropdownMenuItem<String>(
          value: '__header_academic__',
          enabled: false,
          child: Text(
            'Année scolaire',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      for (final period in academicPeriods) {
        final name = period['name'] as String;
        items.add(
          DropdownMenuItem<String>(
            value: name,
            child: _buildDropdownItem(period, isDynamic: false),
          ),
        );
      }
    }

    final selectedValue = widget.selectedPeriod?['name'] as String?;
    final String selectedLabel = widget.selectedPeriod?['name'] as String? ?? 'Sélectionner une période';
    final String? selectedDateRange = _buildDateRangeLabel(widget.selectedPeriod);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.violet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: AppTheme.violet,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Période',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedValue,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.violet,
                      size: 20,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    menuMaxHeight: 400,
                    itemHeight: 48,
                    selectedItemBuilder: (context) {
                      return items.map((item) {
                        if (item.value?.startsWith('__') == true) {
                          return const SizedBox.shrink();
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    selectedLabel,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.nightBlue,
                                      height: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (selectedDateRange != null)
                                    Text(
                                      selectedDateRange,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        height: 1.1,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                    items: items,
                    onChanged: (name) {
                      if (name != null && !name.startsWith('__')) {
                        final period = widget.periods.firstWhere(
                          (p) => p['name'] == name,
                        );
                        widget.onPeriodChanged(period);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem(Map<String, dynamic> period, {required bool isDynamic}) {
    final name = period['name'] as String? ?? 'Inconnu';
    final startDate = period['start_date'] as String?;
    final endDate = period['end_date'] as String?;
    final bool isActive = period['is_active'] == true;

    final Color indicatorColor = isDynamic
        ? Colors.blue
        : isActive
            ? Colors.green
            : Colors.grey[400]!;

    String? dateRange;
    if (startDate != null && endDate != null) {
      dateRange = '${_formatShortDate(startDate)} → ${_formatShortDate(endDate)}';
    }

    final bool isSelected = widget.selectedPeriod?['name'] == name;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: indicatorColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (dateRange != null) ...[
          const SizedBox(width: 6),
          Text(
            '($dateRange)',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
        if (isActive && !isDynamic) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Actif',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
        if (isSelected) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.check_rounded,
            color: AppTheme.violet,
            size: 16,
          ),
        ],
      ],
    );
  }

  String? _buildDateRangeLabel(Map<String, dynamic>? period) {
    if (period == null) return null;
    final startDate = period['start_date'] as String?;
    final endDate = period['end_date'] as String?;
    if (startDate == null || endDate == null) return null;

    if (startDate == endDate) {
      return _formatFullDate(startDate);
    }
    return '${_formatShortDate(startDate)} → ${_formatShortDate(endDate)}';
  }

  String _formatShortDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatFullDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}