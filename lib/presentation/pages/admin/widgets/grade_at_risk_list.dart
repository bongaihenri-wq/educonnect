// lib/presentation/pages/admin/widgets/grade_at_risk_list.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class GradeAtRiskList extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  // Format: [{'name': 'KOUASSI Jean', 'class': '5ème1', 'average': 4.5, 'matricule': '...'}, ...]
  final Function(Map<String, dynamic> student) onStudentTap;

  const GradeAtRiskList({
    super.key,
    required this.students,
    required this.onStudentTap,
  });

  @override
  State<GradeAtRiskList> createState() => _GradeAtRiskListState();
}

class _GradeAtRiskListState extends State<GradeAtRiskList> {
  double _riskThreshold = 8.0; // Seuil par défaut

  final List<double> _thresholdOptions = [5.0, 7.5, 8.0, 9.0, 10.0];

  List<Map<String, dynamic>> get _atRiskStudents {
    return widget.students.where((s) {
      final avg = (s['average'] as num?)?.toDouble() ?? 20.0;
      return avg < _riskThreshold;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final atRisk = _atRiskStudents;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header avec sélecteur de seuil
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[400], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Élèves à Risque',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.nightBlue,
                    ),
                  ),
                ],
              ),
              // ✅ SÉLECTEUR DE SEUIL DYNAMIQUE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: _riskThreshold,
                    isDense: true,
                    icon: Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey[600]),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                    items: _thresholdOptions.map((threshold) {
                      return DropdownMenuItem<double>(
                        value: threshold,
                        child: Text('< ${threshold.toStringAsFixed(1)}/20'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _riskThreshold = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          Text(
            'Seuil actuel: ${_riskThreshold.toStringAsFixed(1)}/20',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          
          // Compteur
          if (atRisk.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${atRisk.length} élève${atRisk.length > 1 ? 's' : ''} concerné${atRisk.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          // Liste
          if (atRisk.isEmpty)
            _buildEmptyState()
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: atRisk.length,
                  itemBuilder: (context, index) {
                    return _buildStudentRow(atRisk[index]);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(Map<String, dynamic> student) {
    final name = student['name'] ?? 'Inconnu';
    final className = student['class'] ?? '-';
    final average = (student['average'] as num?)?.toDouble() ?? 0.0;
    final matricule = student['matricule'] ?? 'N/A';

    return InkWell(
      onTap: () => widget.onStudentTap(student),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Indicateur sévérité
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getSeverityColor(average),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$className • Matricule: $matricule',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Moyenne
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getSeverityColor(average).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                average.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _getSeverityColor(average),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(double average) {
    if (average < 5) return Colors.red[700]!;
    if (average < _riskThreshold * 0.8) return Colors.red[400]!;
    return Colors.orange;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[400], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucun élève à risque',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  'Seuil: ${_riskThreshold.toStringAsFixed(1)}/20',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}