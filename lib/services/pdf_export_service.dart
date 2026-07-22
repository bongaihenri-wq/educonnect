// lib/services/pdf_export_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'credentials_service.dart';
import '../data/repositories/report_repository.dart';

class PdfExportService {
  /// Exporte une liste de credentials en PDF
  static Future<String?> exportCredentials({
    required List<UserCredential> credentials,
    required String schoolName,
    String? roleFilter,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(schoolName, roleFilter),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildTable(credentials),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName =
          'identifiants_${schoolName.replaceAll(' ', '_')}_$timestamp.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      debugPrint('❌ Erreur export PDF: $e');
      return null;
    }
  }

  static pw.Widget _buildHeader(String schoolName, String? roleFilter) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'EduConnect - Identifiants de connexion',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.purple800,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'École: $schoolName',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        if (roleFilter != null)
          pw.Text(
            'Filtre: ${roleFilter == 'parent' ? 'Parents' : 'Enseignants'}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildTable(List<UserCredential> credentials) {
    return pw.Table.fromTextArray(
      headers: ['Nom', 'Rôle', 'Téléphone', 'Mot de passe', 'Matricule'],
      data: credentials
          .map((c) => [
                c.fullName,
                c.displayRole,
                c.phone,
                c.generatedPassword,
                c.matricule ?? '-',
              ])
          .toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.purple700),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Document confidentiel - EduConnect',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
        pw.Text(
          'Page ${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }

  /// Partager le PDF
  static Future<void> sharePdf(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Identifiants EduConnect',
    );
  }

  // ============================================================
  // EXPORTS ENSEIGNANT — NOTES
  // ============================================================

  static Future<String?> exportTeacherGrades({
    required ClassGradeStats grades,
    required String className,
    required String periodName,
    required String teacherName,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildTeacherHeader(
            title: 'Relevé de Notes',
            className: className,
            periodName: periodName,
            teacherName: teacherName,
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildGradesSummary(grades),
            pw.SizedBox(height: 20),
            _buildGradesTable(grades),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'notes_${className.replaceAll(' ', '_')}_$timestamp.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      debugPrint('❌ Erreur export notes PDF: $e');
      return null;
    }
  }

  // ============================================================
  // EXPORTS ENSEIGNANT — PRÉSENCES
  // ============================================================

  static Future<String?> exportTeacherAttendance({
    required ClassAttendanceStats attendance,
    required String className,
    required String periodName,
    required String teacherName,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildTeacherHeader(
            title: 'Relevé de Présences',
            className: className,
            periodName: periodName,
            teacherName: teacherName,
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildAttendanceSummary(attendance),
            pw.SizedBox(height: 20),
            _buildAttendanceTable(attendance),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName =
          'presences_${className.replaceAll(' ', '_')}_$timestamp.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      debugPrint('❌ Erreur export présences PDF: $e');
      return null;
    }
  }

  // ============================================================
  // HELPERS PDF ENSEIGNANT
  // ============================================================

  static pw.Widget _buildTeacherHeader({
    required String title,
    required String className,
    required String periodName,
    required String teacherName,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'EduConnect - $title',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.purple800,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Classe: $className', style: const pw.TextStyle(fontSize: 11)),
        pw.Text('Période: $periodName',
            style: const pw.TextStyle(fontSize: 11)),
        pw.Text('Enseignant: $teacherName',
            style: const pw.TextStyle(fontSize: 11)),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildGradesSummary(ClassGradeStats grades) {
    final avgByType = grades.averageByType;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Résumé',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(
              'Moyenne classe: ${grades.classAverage.toStringAsFixed(2)}/20'),
          pw.Text(
              '> 15: ${grades.above15Count} | 12-15: ${grades.between12And15Count} | 10-12: ${grades.between10And12Count} | < 10: ${grades.below10Count}'),
          if (avgByType.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Moyennes par type:'),
            ...avgByType.entries.map((e) => pw.Text(
                '  ${e.key}: ${e.value?.toStringAsFixed(2) ?? 'N/A'}/20')),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildGradesTable(ClassGradeStats grades) {
    return pw.Table.fromTextArray(
      headers: ['Élève', 'Type', 'Note', 'Coef', 'Date'],
      data: grades.grades
          .map((g) => [
                g.studentName,
                g.type,
                '${g.value.toStringAsFixed(1)}/${g.outOf.toStringAsFixed(0)}',
                '${g.coefficient}',
                '${g.date.day}/${g.date.month}/${g.date.year}',
              ])
          .toList(),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.purple700),
      cellHeight: 25,
    );
  }

  static pw.Widget _buildAttendanceSummary(ClassAttendanceStats attendance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Résumé',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(
              'Taux de présence: ${attendance.classPresenceRate.toStringAsFixed(1)}%'),
          pw.Text('Total absences: ${attendance.totalAbsences}'),
          if (attendance.topAbsentStudents.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Élèves les plus absents:'),
            ...attendance.topAbsentStudents.take(5).map((s) =>
                pw.Text('  ${s.studentName}: ${s.absenceCount} absence(s)')),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildAttendanceTable(ClassAttendanceStats attendance) {
    return pw.Table.fromTextArray(
      headers: ['Date', 'Présents', 'Absents', 'Retards', 'Taux'],
      data: attendance.dailyAttendance
          .map((d) => [
                d.date,
                '${d.present}',
                '${d.absent}',
                '${d.late}',
                '${d.present + d.absent + d.late > 0 ? ((d.present / (d.present + d.absent + d.late)) * 100).toStringAsFixed(0) : 0}%',
              ])
          .toList(),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.purple700),
      cellHeight: 25,
    );
  }
}
