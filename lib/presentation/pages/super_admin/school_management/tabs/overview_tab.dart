import 'package:flutter/material.dart';
import '/../../config/theme.dart';
import '../widgets/import_indicator.dart';
import '../widgets/stat_card.dart';
import '../widgets/info_row.dart';

class OverviewTab extends StatelessWidget {
  final Map<String, dynamic> school;
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> parents;
  final List<Map<String, dynamic>> schedules;
  final bool hasStudentsParents;
  final bool hasTeachers;
  final bool hasSchedules;
  final VoidCallback onImport;

  const OverviewTab({
    super.key,
    required this.school,
    required this.classes,
    required this.teachers,
    required this.students,
    required this.parents,
    required this.schedules,
    required this.hasStudentsParents,
    required this.hasTeachers,
    required this.hasSchedules,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImportIndicators(),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildSchoolInfo(),
        ],
      ),
    );
  }

  Widget _buildImportIndicators() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'État des imports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ImportIndicator(
              icon: Icons.people,
              label: 'Élèves & Parents',
              isComplete: hasStudentsParents,
              count: '${students.length} élèves, ${parents.length} parents',
            ),
            const Divider(),
            ImportIndicator(
              icon: Icons.person_outline,
              label: 'Enseignants',
              isComplete: hasTeachers,
              count: '${teachers.length} enseignants',
            ),
            const Divider(),
            ImportIndicator(
              icon: Icons.calendar_today,
              label: 'Emploi du temps',
              isComplete: hasSchedules,
              count: '${schedules.length} cours',
            ),
            if (!hasStudentsParents || !hasTeachers || !hasSchedules) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Certains fichiers n\'ont pas été importés. Cliquez sur + pour importer.',
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        StatCard(icon: Icons.class_, label: 'Classes', value: classes.length.toString(), color: Colors.blue),
        StatCard(icon: Icons.person_outline, label: 'Enseignants', value: teachers.length.toString(), color: Colors.orange),
        StatCard(icon: Icons.people, label: 'Élèves', value: students.length.toString(), color: Colors.green),
        StatCard(icon: Icons.family_restroom, label: 'Parents', value: parents.length.toString(), color: Colors.purple),
      ],
    );
  }

  Widget _buildSchoolInfo() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InfoRow(icon: Icons.code, label: 'Code', value: school['school_code'] ?? '---'),
            InfoRow(icon: Icons.location_on, label: 'Adresse', value: school['address'] ?? 'Non renseignée'),
            InfoRow(icon: Icons.phone, label: 'Téléphone', value: school['phone'] ?? 'Non renseigné'),
            InfoRow(icon: Icons.email, label: 'Email', value: school['email'] ?? 'Non renseigné'),
            InfoRow(icon: Icons.payment, label: 'Forfait', value: (school['plan_type'] ?? 'basic').toUpperCase()),
            InfoRow(icon: Icons.attach_money, label: 'Frais mensuel', value: '${school['monthly_fee'] ?? 5000} XOF'),
          ],
        ),
      ),
    );
  }
}