import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

class CsvParserService {
  static List<Map<String, dynamic>> parse(String content, {String? fileExtension}) {
    // Si c'est un Excel, convertir en CSV string d'abord
    if (fileExtension?.toLowerCase() == 'xlsx') {
      content = _convertExcelToCsv(content);
    }
    
    // Détecte le séparateur (virgule ou tabulation)
    final separator = _detectSeparator(content);
    
    final rows = CsvToListConverter(
      fieldDelimiter: separator,
      eol: '\n',
    ).convert(content);
    
    if (rows.isEmpty) return [];
    
    final headers = rows.first.map((h) => h.toString().trim().toLowerCase()).toList();
    final data = <Map<String, dynamic>>[];
    
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      // Ignore les lignes vides
      if (row.isEmpty || row.every((cell) => cell?.toString().trim().isEmpty ?? true)) continue;
      
      final map = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        map[headers[j]] = row[j]?.toString().trim();
      }
      data.add(map);
    }
    return data;
  }

  static String _detectSeparator(String content) {
    // Compte les occurrences de chaque séparateur potentiel
    final commaCount = content.split(',').length;
    final tabCount = content.split('\t').length;
    final semicolonCount = content.split(';').length;
    
    // Retourne le séparateur le plus fréquent
    if (tabCount > commaCount && tabCount > semicolonCount) return '\t';
    if (semicolonCount > commaCount && semicolonCount > tabCount) return ';';
    return ','; // Défaut: virgule
  }

  static String _convertExcelToCsv(String bytesAsString) {
    try {
      final bytes = bytesAsString.codeUnits;
      final excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;
      
      final buffer = StringBuffer();
      for (final row in sheet.rows) {
        final cells = row.map((cell) {
          final value = cell?.value;
          if (value == null) return '';
          // Échapper les virgules et guillemets
          final stringValue = value.toString();
          if (stringValue.contains(',') || stringValue.contains('"')) {
            return '"${stringValue.replaceAll('"', '""')}"';
          }
          return stringValue;
        }).join(',');
        buffer.writeln(cells);
      }
      return buffer.toString();
    } catch (e) {
      print('❌ Erreur conversion Excel: $e');
      return '';
    }
  }

  static List<String> validateRow(Map<String, dynamic> row, String type) {
    final errors = <String>[];
    
    switch (type) {
      case 'students_parents':
        if (row['matricule']?.toString().isEmpty ?? true) errors.add('matricule manquant');
        if (row['eleve_nom']?.toString().isEmpty ?? true) errors.add('eleve_nom manquant');
        if (row['parent_telephone']?.toString().isEmpty ?? true) errors.add('parent_telephone manquant');
        break;
      case 'teachers':
        if (row['email']?.toString().isEmpty ?? true) errors.add('email manquant');
        if (row['nom']?.toString().isEmpty ?? true) errors.add('nom manquant');
        break;
      case 'schedules':
        if (row['classe']?.toString().isEmpty ?? true) errors.add('classe manquante');
        if (row['jour']?.toString().isEmpty ?? true) errors.add('jour manquant');
        break;
    }
    return errors;
  }
}