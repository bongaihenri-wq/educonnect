import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class RoleSelector extends StatelessWidget {
  final bool isParentMode;
  final Function(bool) onChanged;

  const RoleSelector({super.key, required this.isParentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppTheme.bisDark.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildBtn("Parent", isParentMode, () => onChanged(true), AppTheme.teal),
          _buildBtn("Enseignant", !isParentMode, () => onChanged(false), AppTheme.violet),
        ],
      ),
    );
  }

  Widget _buildBtn(String label, bool active, VoidCallback tap, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: active ? color : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : AppTheme.nightBlue, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
