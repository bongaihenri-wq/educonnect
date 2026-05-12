// lib/services/csv_parser_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

class CsvParserService {
  static List<Map<String, dynamic>> parse({
    required String? filePath,
    required Uint8List? bytes,
    required String fileExtension,
  }) {
    String content;
    
    if (fileExtension.toLowerCase() == 'xlsx' || fileExtension.toLowerCase() == 'xls') {
      if (bytes == null) throw Exception('Bytes manquants pour Excel');
      content = _convertExcelToCsv(bytes);
    } else {
      if (filePath == null) throw Exception('Chemin fichier manquant pour CSV');
      final file = File(filePath);
      content = file.readAsStringSync(encoding: utf8);
    }
    
    content = content.replaceAll('\uFEFF', '');
    
    final separator = _detectSeparator(content);
    print('📊 Séparateur: "${separator == '\t' ? 'TAB' : separator}"');
    
    final rows = CsvToListConverter(
      fieldDelimiter: separator,
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(content);
    
    if (rows.isEmpty) return [];
    
    final headers = rows.first.map((h) {
      return h.toString()
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('-', '_');
    }).toList();
    
    print('📋 Headers: $headers');
    
    final data = <Map<String, dynamic>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((cell) => cell?.toString().trim().isEmpty ?? true)) continue;
      
      final map = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        map[headers[j]] = row[j]?.toString().trim() ?? '';
      }
      map['_raw_row_number'] = i + 1;
      data.add(map);
    }
    
    print('📊 ${data.length} lignes parsées');
    return data;
  }

  static String _detectSeparator(String content) {
    final sample = content.split('\n').take(5).join('\n');
    final commaCount = sample.split(',').length;
    final tabCount = sample.split('\t').length;
    final semicolonCount = sample.split(';').length;
    
    if (tabCount > commaCount && tabCount > semicolonCount) return '\t';
    if (semicolonCount > commaCount && semicolonCount > tabCount) return ';';
    return ',';
  }

  /// 🔧 VERSION ULTRA-ROBUSTE: Utilise toString() + parsing manuel
  static String _convertExcelToCsv(Uint8List bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;
      
      print('📊 Feuille: $sheetName, ${sheet.maxRows} lignes');
      
      final buffer = StringBuffer();
      
      for (var i = 0; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty) continue;
        
        final cells = row.map((cell) {
          // 🔧 EXTRACTEUR ULTRA-SIMPLE: toString() + parse manuel
          final rawString = _cellToString(cell);
          
          if (rawString.isEmpty) return '';
          
          // 🔧 Détecte et convertit les dates/heures Excel
          final timeString = _parseExcelTime(rawString);
          if (timeString != null) {
            return timeString; // Retourne HH:MM:SS
          }
          
          // Échappe les virgules et guillemets pour CSV
          if (rawString.contains(',') || rawString.contains('"') || rawString.contains('\n')) {
            return '"${rawString.replaceAll('"', '""')}"';
          }
          return rawString;
        }).join(',');
        
        buffer.writeln(cells);
      }
      
      final result = buffer.toString();
      print('📊 CSV généré: ${result.length} caractères');
      return result;
      
    } catch (e, stackTrace) {
      print('❌ Erreur Excel: $e');
      print('❌ Stack: $stackTrace');
      throw Exception('Impossible de lire Excel: $e');
    }
  }

  // ============================================
  // 🔧 EXTRACTEUR ULTRA-SIMPLE: toString() uniquement
  // ============================================

  static String _cellToString(dynamic cell) {
    if (cell == null) return '';
    
    try {
      // Essaie d'accéder à value puis toString
      final dynamic value = cell.value;
      if (value == null) return '';
      
      // value.toString() fonctionne pour TOUT type de CellValue
      return value.toString();
    } catch (e) {
      // Fallback ultime
      return cell.toString();
    }
  }

  // ============================================
  // 🔧 PARSEUR MANUEL DE TEMPS EXCEL
  // ============================================

  /// Détecte et convertit n'importe quel format de temps Excel en HH:MM:SS
  static String? _parseExcelTime(String raw) {
    final trimmed = raw.trim();
    
    // Déjà au format HH:MM:SS
    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(trimmed)) {
      return trimmed;
    }
    
    // Format HH:MM
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(trimmed)) {
      return "$trimmed:00";
    }
    
    // Format H:MM
    if (RegExp(r'^\d{1}:\d{2}$').hasMatch(trimmed)) {
      return "0$trimmed:00";
    }
    
    // Format avec h (8h10)
    final hMatch = RegExp(r'^(\d{1,2})[hH](\d{2})$').firstMatch(trimmed);
    if (hMatch != null) {
      return "${hMatch.group(1)!.padLeft(2, '0')}:${hMatch.group(2)!}:00";
    }
    
    // Format 4 chiffres (0810)
    if (RegExp(r'^\d{4}$').hasMatch(trimmed)) {
      return "${trimmed.substring(0, 2)}:${trimmed.substring(2)}:00";
    }
    
    // Format ISO avec T (2024-01-15T08:10:00)
    if (trimmed.contains('T')) {
      final timePart = trimmed.split('T')[1];
      if (timePart.length >= 8) return timePart.substring(0, 8);
      if (timePart.length == 5) return "$timePart:00";
    }
    
    // Format datetime avec espace (2024-01-15 08:10:00)
    if (trimmed.contains(' ')) {
      final parts = trimmed.split(' ');
      final timePart = parts.last;
      if (RegExp(r'^\d{2}:\d{2}(:\d{2})?$').hasMatch(timePart)) {
        return timePart.length == 5 ? "$timePart:00" : timePart;
      }
    }
    
    // Nombre Excel (0.340277 = fraction de jour)
    if (RegExp(r'^\d+\.\d+$').hasMatch(trimmed)) {
      try {
        final fraction = double.parse(trimmed);
        if (fraction > 0 && fraction < 1) {
          final totalMinutes = (fraction * 24 * 60).round();
          final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
          final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
          return "$hours:$minutes:00";
        }
      } catch (_) {}
    }
    
    // Pas un temps, retourne null pour traitement normal
    return null;
  }

  static List<String> validateRow(Map<String, dynamic> row, String type) {
    final errors = <String>[];
    
    switch (type) {
      case 'students_parents':
        if (_isEmpty(row['matricule'])) errors.add('matricule manquant');
        if (_isEmpty(row['eleve_nom'])) errors.add('eleve_nom manquant');
        if (_isEmpty(row['parent_telephone'])) errors.add('parent_telephone manquant');
        break;
        
      case 'teachers':
        if (_isEmpty(row['nom'])) errors.add('nom manquant');
        if (_isEmpty(row['telephone'])) errors.add('telephone manquant');
        break;
        
      case 'schedules':
        if (_isEmpty(row['classe'])) errors.add('classe manquante');
        if (_isEmpty(row['jour'])) errors.add('jour manquant');
        final hasStartTime = !_isEmpty(row['heure_debut']) || 
                            !_isEmpty(row['start_time']) ||
                            !_isEmpty(row['heuredebut']) ||
                            !_isEmpty(row['debut']);
        final hasEndTime = !_isEmpty(row['heure_fin']) || 
                          !_isEmpty(row['end_time']) ||
                          !_isEmpty(row['heurefin']) ||
                          !_isEmpty(row['fin']);
        if (!hasStartTime) errors.add('heure_debut manquante');
        if (!hasEndTime) errors.add('heure_fin manquante');
        break;
    }
    return errors;
  }

  static bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    return false;
  }
}