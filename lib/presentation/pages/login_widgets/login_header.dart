import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.school_rounded, size: 50, color: AppTheme.teal),
        ),
        const SizedBox(height: 16),
        Text("EduConnect", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.nightBlue)),
        Text("Gestion Scolaire Intelligente", style: TextStyle(color: AppTheme.bisDark, fontSize: 14)),
      ],
    );
  }
}
