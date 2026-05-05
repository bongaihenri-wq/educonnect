import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class SchoolField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final bool isValidating;
  final bool isVerified;
  final String? schoolName;

  const SchoolField({super.key, required this.controller, required this.onChanged, required this.isValidating, required this.isVerified, this.schoolName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.withOpacity(0.05) : Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isVerified ? Colors.green.withOpacity(0.3) : Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'CODE ÉCOLE',
              prefixIcon: Icon(Icons.apartment, color: isVerified ? Colors.green : Colors.amber),
              suffixIcon: isValidating ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null,
              border: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
          if (schoolName != null)
            Text('🏫 $schoolName', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
