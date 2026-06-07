// lib/presentation/pages/admin/widgets/student_detail_dialog.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import './../widgets/responsive_dialog.dart';
import '../../../widgets/charts/stacked_attendance_bar.dart';

class StudentDetailDialog extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String matricule;
  final String gender;
  final Map<String, dynamic> stats;

  const StudentDetailDialog({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.matricule,
    required this.gender,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final presentCount = stats['present_count'] ?? 0;
    final absentCount = stats['absent_count'] ?? 0;
    final lateCount = stats['late_count'] ?? 0;
    final totalRecords = stats['total_records'] ?? 0;
    final presentRate = (stats['present_rate_pct'] as num?)?.toDouble() ?? 0.0;
    final absentRate = (stats['absent_rate_pct'] as num?)?.toDouble() ?? 0.0;
    final lateRate = (stats['late_rate_pct'] as num?)?.toDouble() ?? 0.0;

    final isFemale = gender == 'f' || gender == 'female' || gender == 'feminin';

    return ResponsiveDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header compact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.violet,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isFemale ? Colors.pink[100] : Colors.blue[100],
                  child: Icon(
                    isFemale ? Icons.female : Icons.male,
                    size: 24,
                    color: isFemale ? Colors.pink : Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Matricule: $matricule',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Contenu scrollable
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assiduité (30 derniers jours)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.nightBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    StackedAttendanceBar(
                      label: 'Répartition',
                      presentPercent: presentRate,
                      absentPercent: absentRate,
                      latePercent: lateRate,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Stats compactes
                    Row(
                      children: [
                        _buildStatBox('Présences', '$presentCount', Colors.green),
                        const SizedBox(width: 8),
                        _buildStatBox('Absences', '$absentCount', Colors.red),
                        const SizedBox(width: 8),
                        _buildStatBox('Retards', '$lateCount', Colors.orange),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Taux global
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.violet.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.trending_up, color: AppTheme.violet, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Taux: ${presentRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.violet,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Center(
                      child: Text(
                        'Total: $totalRecords enregistrements',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bouton fermer
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Fermer'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}