import 'package:flutter/material.dart';
import '/../data/models/class_model.dart';

class ClassSelectorCard extends StatelessWidget {
  final List<ClassModel> classes;
  final ClassModel? selectedClass;
  final Function(ClassModel) onClassSelected;

  const ClassSelectorCard({
    super.key,
    required this.classes,
    this.selectedClass,
    required this.onClassSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(),
          const SizedBox(height: 16),
          classes.isEmpty ? _buildEmptyState() : _buildDropdown(),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _buildLabel() => Row(
        children: [
          _buildIcon(Icons.school_outlined),
          const SizedBox(width: 12),
          const Text('Classe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _buildIcon(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: const Color(0xFF7C3AED)),
      );

  Widget _buildEmptyState() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
        child: const Text('Aucune classe assignée', style: TextStyle(color: Color(0xFF64748B))),
      );

  Widget _buildDropdown() => DropdownButtonFormField<ClassModel>(
        value: selectedClass,
        isExpanded: true,
        decoration: _inputDecoration(),
        hint: const Text('Sélectionner une classe'),
        items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
        onChanged: (val) => val != null ? onClassSelected(val) : null,
      );

  InputDecoration _inputDecoration() => InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );
}
