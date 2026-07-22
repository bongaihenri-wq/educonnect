// lib/services/excel_export_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'credentials_service.dart';
import '../data/repositories/report_repository.dart';

class ExcelExportService {
  /// Exporte une liste de credentials en Excel
  static Future<String?> exportCredentials({
    required List<UserCredential> credentials,
    required String schoolName,
    String? roleFilter,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Identifiants'];

      // Style d'en-tête
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.purple700,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
      );

      // En-têtes
      sheet.appendRow([
        TextCellValue('Nom'),
        TextCellValue('Rôle'),
        TextCellValue('Téléphone'),
        TextCellValue('Mot de passe'),
        TextCellValue('Matricule Enfant'),
      ]);

      // Appliquer style aux en-têtes
      for (int i = 0; i < 5; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..cellStyle = headerStyle;
      }

      // Données
      for (final cred in credentials) {
        sheet.appendRow([
          TextCellValue(cred.fullName),
          TextCellValue(cred.displayRole),
          TextCellValue(cred.phone),
          TextCellValue(cred.generatedPassword),
          TextCellValue(cred.matricule ?? '-'),
        ]);
      }

      // Ajuster largeurs colonnes
      sheet.setColumnWidth(0, 25);
      sheet.setColumnWidth(1, 15);
      sheet.setColumnWidth(2, 18);
      sheet.setColumnWidth(3, 20);
      sheet.setColumnWidth(4, 20);

      // Sauvegarder
      final output = await getTemporaryDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName =
          'identifiants_${schoolName.replaceAll(' ', '_')}_$timestamp.xlsx';
      final file = File('${output.path}/$fileName');

      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur export Excel: $e');
      return null;
    }
  }

  /// Partager le fichier Excel
  static Future<void> shareExcel(String filePath) async {
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
      final excel = Excel.createExcel();
      final sheet = excel['Notes'];

      // En-tête info
      sheet.appendRow([TextCellValue('EduConnect - Relevé de Notes')]);
      sheet.appendRow([TextCellValue('Classe: $className')]);
      sheet.appendRow([TextCellValue('Période: $periodName')]);
      sheet.appendRow([TextCellValue('Enseignant: $teacherName')]);
      sheet.appendRow([TextCellValue('')]);

      // En-têtes tableau
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.purple700,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
      );

      sheet.appendRow([
        TextCellValue('Élève'),
        TextCellValue('Type'),
        TextCellValue('Note'),
        TextCellValue('Sur'),
        TextCellValue('Coef'),
        TextCellValue('Date'),
      ]);

      for (int i = 0; i < 6; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5))
          ..cellStyle = headerStyle;
      }

      // Données
      for (final g in grades.grades) {
        sheet.appendRow([
          TextCellValue(g.studentName),
          TextCellValue(g.type),
          TextCellValue(g.value.toStringAsFixed(1)),
          TextCellValue(g.outOf.toStringAsFixed(0)),
          TextCellValue('${g.coefficient}'),
          TextCellValue('${g.date.day}/${g.date.month}/${g.date.year}'),
        ]);
      }

      // Résumé
      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([
        TextCellValue(
            'Moyenne classe: ${grades.classAverage.toStringAsFixed(2)}/20')
      ]);

      // Sauvegarder
      final output = await getTemporaryDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName =
          'notes_${className.replaceAll(' ', '_')}_$timestamp.xlsx';
      final file = File('${output.path}/$fileName');

      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur export notes Excel: $e');
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
      final excel = Excel.createExcel();
      final sheet = excel['Présences'];

      // En-tête info
      sheet.appendRow([TextCellValue('EduConnect - Relevé de Présences')]);
      sheet.appendRow([TextCellValue('Classe: $className')]);
      sheet.appendRow([TextCellValue('Période: $periodName')]);
      sheet.appendRow([TextCellValue('Enseignant: $teacherName')]);
      sheet.appendRow([TextCellValue('')]);

      // En-têtes tableau
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.purple700,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
      );

      sheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Présents'),
        TextCellValue('Absents'),
        TextCellValue('Retards'),
        TextCellValue('Taux présence'),
      ]);

      for (int i = 0; i < 5; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5))
          ..cellStyle = headerStyle;
      }

      // Données journalières
      for (final d in attendance.dailyAttendance) {
        final total = d.present + d.absent + d.late;
        final rate =
            total > 0 ? ((d.present / total) * 100).toStringAsFixed(0) : '0';

        sheet.appendRow([
          TextCellValue(d.date),
          TextCellValue('${d.present}'),
          TextCellValue('${d.absent}'),
          TextCellValue('${d.late}'),
          TextCellValue('$rate%'),
        ]);
      }

      // Top absents
      if (attendance.topAbsentStudents.isNotEmpty) {
        sheet.appendRow([TextCellValue('')]);
        sheet.appendRow([TextCellValue('Élèves les plus absents')]);

        for (final s in attendance.topAbsentStudents.take(5)) {
          sheet.appendRow([
            TextCellValue(s.studentName),
            TextCellValue('${s.absenceCount} absence(s)'),
          ]);
        }
      }

      // Sauvegarder
      final output = await getTemporaryDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName =
          'presences_${className.replaceAll(' ', '_')}_$timestamp.xlsx';
      final file = File('${output.path}/$fileName');

      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur export présences Excel: $e');
      return null;
    }
  }
}
