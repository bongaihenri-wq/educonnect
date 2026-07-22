// lib/presentation/pages/teacher/widgets/report/export_button.dart
import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback? onExportGradesPDF;
  final VoidCallback? onExportGradesExcel;
  final VoidCallback? onExportAttendancePDF;
  final VoidCallback? onExportAttendanceExcel;

  const ExportButton({
    super.key,
    this.onExportGradesPDF,
    this.onExportGradesExcel,
    this.onExportAttendancePDF,
    this.onExportAttendanceExcel,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.violet,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.violet.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.download, color: Colors.white),
      ),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        if (onExportGradesPDF != null || onExportGradesExcel != null)
          _buildMenuHeader('Notes'),
        if (onExportGradesPDF != null)
          _buildMenuItem(
              'PDF', Icons.picture_as_pdf, Colors.red, onExportGradesPDF!),
        if (onExportGradesExcel != null)
          _buildMenuItem(
              'Excel', Icons.table_chart, Colors.green, onExportGradesExcel!),
        if (onExportAttendancePDF != null || onExportAttendanceExcel != null)
          _buildMenuHeader('Présences'),
        if (onExportAttendancePDF != null)
          _buildMenuItem(
              'PDF', Icons.picture_as_pdf, Colors.red, onExportAttendancePDF!),
        if (onExportAttendanceExcel != null)
          _buildMenuItem('Excel', Icons.table_chart, Colors.green,
              onExportAttendanceExcel!),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuHeader(String title) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 20,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return PopupMenuItem<String>(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
