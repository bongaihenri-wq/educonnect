// lib/presentation/blocs/school_report/school_report_exporter.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SchoolReportExporter {
  Future<String> exportToCSV(
    List<Map<String, dynamic>> data,
    String reportType,
  ) async {
    Directory? publicDir;
    String? publicPath;
    try {
      if (Platform.isAndroid) {
        publicDir = Directory('/storage/emulated/0/Download/EduConnect');
        if (!await publicDir.exists()) {
          await publicDir.create(recursive: true);
        }
        publicPath = publicDir.path;
      }
    } catch (e) {
      print('Download public non accessible: $e');
    }

    final localDir = await getApplicationDocumentsDirectory();
    final localPath = '${localDir.path}/educonnect_reports';
    await Directory(localPath).create(recursive: true);

    final now = DateTime.now();
    final fileName =
        'EduConnect_${reportType}_${now.day}${now.month}_${now.hour}${now.minute}.csv';

    final publicFilePath = publicPath != null ? '$publicPath/$fileName' : null;
    final localFilePath = '$localPath/$fileName';

    List<String> headers;
    if (reportType == 'attendance') {
      headers = [
        'Date',
        'Cours',
        'Horaire',
        'Classe',
        'Eleve',
        'Enseignant',
        'Statut'
      ];
    } else {
      headers = ['Date', 'Classe', 'Eleve', 'Matiere', 'Coefficient', 'Note'];
    }

    final csv = StringBuffer();
    csv.writeln(headers.join(';'));

    for (final row in data) {
      final values = _buildRowValues(row, reportType);
      final escapedValues = values.map((v) {
        if (v.contains(';') || v.contains('"')) {
          return '"${v.replaceAll('"', '""')}"';
        }
        return v;
      }).toList();
      csv.writeln(escapedValues.join(';'));
    }

    if (publicFilePath != null) {
      await File(publicFilePath).writeAsString(csv.toString(), encoding: utf8);
      print('✅ CSV public: $publicFilePath');
    }

    await File(localFilePath).writeAsString(csv.toString(), encoding: utf8);
    print('✅ CSV local: $localFilePath');

    return publicFilePath ?? localFilePath;
  }

  Future<String> exportToHTML(
    List<Map<String, dynamic>> data,
    String reportType,
  ) async {
    Directory? publicDir;
    String? publicPath;
    try {
      if (Platform.isAndroid) {
        publicDir = Directory('/storage/emulated/0/Download/EduConnect');
        if (!await publicDir.exists()) {
          await publicDir.create(recursive: true);
        }
        publicPath = publicDir.path;
      }
    } catch (e) {
      print('Download public non accessible: $e');
    }

    final localDir = await getApplicationDocumentsDirectory();
    final localPath = '${localDir.path}/educonnect_reports';
    await Directory(localPath).create(recursive: true);

    final now = DateTime.now();
    final fileName =
        'EduConnect_${reportType}_${now.day}${now.month}_${now.hour}${now.minute}.html';

    final publicFilePath = publicPath != null ? '$publicPath/$fileName' : null;
    final localFilePath = '$localPath/$fileName';

    final title =
        reportType == 'attendance' ? "Rapport d'Assiduite" : "Rapport de Notes";

    final html = StringBuffer();
    html.writeln('<!DOCTYPE html>');
    html.writeln('<html><head><meta charset="UTF-8">');
    html.writeln('<title>$title</title>');
    html.writeln(_htmlStyles);
    html.writeln('</head><body>');
    html.writeln('<h1>$title</h1>');
    html.writeln(
        '<p class="meta">Genere le ${now.day}/${now.month}/${now.year} • ${data.length} enregistrements</p>');
    html.writeln('<table><thead><tr>');

    if (reportType == 'attendance') {
      html.writeln(
          '<th>Date</th><th>Cours</th><th>Horaire</th><th>Classe</th><th>Eleve</th><th>Enseignant</th><th>Statut</th></tr></thead><tbody>');
      for (final row in data) {
        html.writeln(_buildAttendanceRow(row));
      }
    } else {
      html.writeln(
          '<th>Date</th><th>Classe</th><th>Eleve</th><th>Matiere</th><th>Coef</th><th>Note</th></tr></thead><tbody>');
      for (final row in data) {
        html.writeln(_buildGradeRow(row));
      }
    }

    html.writeln('</tbody></table></body></html>');

    if (publicFilePath != null) {
      await File(publicFilePath).writeAsString(html.toString(), encoding: utf8);
      print('✅ HTML public: $publicFilePath');
    }

    await File(localFilePath).writeAsString(html.toString(), encoding: utf8);
    print('✅ HTML local: $localFilePath');

    return publicFilePath ?? localFilePath;
  }

  List<String> _buildRowValues(Map<String, dynamic> row, String reportType) {
    if (reportType == 'attendance') {
      final dateStr = row['date'] as String?;
      final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
      final schedule = row['schedules'] as Map<String, dynamic>?;
      final student = row['students'] as Map<String, dynamic>?;
      final teacher = row['teachers'] as Map<String, dynamic>?;

      return [
        date != null ? '${date.day}/${date.month}/${date.year}' : '-',
        schedule?['subjects']?['name']?.toString() ?? '-',
        '${schedule?['start_time']?.toString() ?? '--:--'}-${schedule?['end_time']?.toString() ?? '--:--'}',
        '${schedule?['classes']?['level']?.toString() ?? ''} ${schedule?['classes']?['name']?.toString() ?? ''}'
            .trim(),
        '${student?['last_name']?.toString() ?? ''} ${student?['first_name']?.toString() ?? ''}'
            .trim(),
        '${teacher?['last_name']?.toString() ?? ''} ${teacher?['first_name']?.toString() ?? ''}'
            .trim(),
        row['status']?.toString() ?? '-',
      ];
    } else {
      final dateStr = row['date'] as String?;
      final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
      final student = row['students'] as Map<String, dynamic>?;
      final classe = row['classes'] as Map<String, dynamic>?;
      final score = (row['score'] as num?)?.toDouble() ?? 0;
      final maxScore = (row['max_score'] as num?)?.toDouble() ?? 20;
      final coefficient = (row['coefficient'] as num?)?.toDouble() ?? 1;
      final noteSur20 = maxScore > 0 ? (score / maxScore) * 20 : 0;

      return [
        date != null ? '${date.day}/${date.month}/${date.year}' : '-',
        '${classe?['level']?.toString() ?? ''} ${classe?['name']?.toString() ?? ''}'
            .trim(),
        '${student?['last_name']?.toString() ?? ''} ${student?['first_name']?.toString() ?? ''}'
            .trim(),
        row['subjects']?['name']?.toString() ?? '-',
        coefficient.toString(),
        '${noteSur20.toStringAsFixed(2)}/20',
      ];
    }
  }

  String _buildAttendanceRow(Map<String, dynamic> row) {
    final dateStr = row['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final schedule = row['schedules'] as Map<String, dynamic>?;
    final student = row['students'] as Map<String, dynamic>?;
    final teacher = row['teachers'] as Map<String, dynamic>?;
    final status = row['status'] as String? ?? '-';

    final statusClass = status == 'present'
        ? 'present'
        : status == 'absent'
            ? 'absent'
            : status == 'late'
                ? 'late'
                : '';
    final statusLabel = status == 'present'
        ? 'Present'
        : status == 'absent'
            ? 'Absent'
            : status == 'late'
                ? 'Retard'
                : '-';

    return '''
<tr>
<td>${date != null ? '${date.day}/${date.month}/${date.year}' : '-'}</td>
<td>${schedule?['subjects']?['name']?.toString() ?? '-'}</td>
<td>${schedule?['start_time']?.toString() ?? '--:--'}-${schedule?['end_time']?.toString() ?? '--:--'}</td>
<td>${schedule?['classes']?['level']?.toString() ?? ''} ${schedule?['classes']?['name']?.toString() ?? ''}</td>
<td>${student?['last_name']?.toString() ?? ''} ${student?['first_name']?.toString() ?? ''}</td>
<td>${teacher?['last_name']?.toString() ?? ''} ${teacher?['first_name']?.toString() ?? ''}</td>
<td class="$statusClass">$statusLabel</td>
</tr>''';
  }

  String _buildGradeRow(Map<String, dynamic> row) {
    final dateStr = row['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final student = row['students'] as Map<String, dynamic>?;
    final classe = row['classes'] as Map<String, dynamic>?;
    final score = (row['score'] as num?)?.toDouble() ?? 0;
    final maxScore = (row['max_score'] as num?)?.toDouble() ?? 20;
    final noteSur20 = maxScore > 0 ? (score / maxScore) * 20 : 0;

    final noteClass = noteSur20 >= 14
        ? 'note-green'
        : noteSur20 >= 10
            ? 'note-orange'
            : 'note-red';

    return '''
<tr>
<td>${date != null ? '${date.day}/${date.month}/${date.year}' : '-'}</td>
<td>${classe?['level']?.toString() ?? ''} ${classe?['name']?.toString() ?? ''}</td>
<td>${student?['last_name']?.toString() ?? ''} ${student?['first_name']?.toString() ?? ''}</td>
<td>${row['subjects']?['name']?.toString() ?? '-'}</td>
<td>${row['coefficient'] ?? 1}</td>
<td class="$noteClass">${noteSur20.toStringAsFixed(1)}/20</td>
</tr>''';
  }

  static const String _htmlStyles = '''
<style>
body { font-family: Arial, sans-serif; margin: 20px; }
h1 { color: #6B4EFF; border-bottom: 2px solid #6B4EFF; padding-bottom: 10px; }
.meta { color: #666; margin-bottom: 20px; }
table { border-collapse: collapse; width: 100%; margin-top: 20px; }
th { background-color: #6B4EFF; color: white; padding: 10px; text-align: left; }
td { border: 1px solid #ddd; padding: 8px; }
tr:nth-child(even) { background-color: #f8f9fe; }
.present { color: green; font-weight: bold; }
.absent { color: red; font-weight: bold; }
.late { color: orange; font-weight: bold; }
.note-green { color: green; font-weight: bold; }
.note-orange { color: orange; font-weight: bold; }
.note-red { color: red; font-weight: bold; }
</style>''';
}
