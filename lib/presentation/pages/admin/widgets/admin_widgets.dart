import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

// --- LE HEADER ---
class AdminHeaderCard extends StatelessWidget {
  final String adminName;
  final String schoolName;

  const AdminHeaderCard({super.key, required this.adminName, required this.schoolName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.nightBlue, Color(0xFF5B21B6)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Administration 🏫', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(adminName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
            child: Text(schoolName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// --- LES STATISTIQUES ---
class AdminStatsGrid extends StatelessWidget {
  const AdminStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vue d\'ensemble', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.nightBlue)),
          const SizedBox(height: 16),
          _row([
            _stat(Icons.people, '452', 'Élèves', AppTheme.violet),
            _stat(Icons.school, '28', 'Classes', const Color(0xFF14B8A6)),
          ]),
          const SizedBox(height: 12),
          _row([
            _stat(Icons.person, '34', 'Profs', const Color(0xFFF59E0B)),
            _stat(Icons.family_restroom, '386', 'Parents', const Color(0xFFFB7185)),
          ]),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) => Row(children: children.expand((w) => [w, const SizedBox(width: 12)]).toList()..removeLast());

  Widget _stat(IconData icon, String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bisDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// --- LA TUILE D'ACTION ---
class AdminActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const AdminActionTile({super.key, required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bisDark),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}
