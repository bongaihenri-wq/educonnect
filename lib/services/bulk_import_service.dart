// lib/services/bulk_import_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BulkImportService {
  static String get _functionUrl => 
      dotenv.env['SUPABASE_FUNCTION_URL'] ?? 
      'https://vethtvfdkywbzxzwckdl.supabase.co/functions/v1/bulk-import';
  
  // 🔥 REVIENT À TA VERSION ORIGINALE : Service Role Key
  static String get _serviceRoleKey => 
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  static const List<String> validTypes = [
    'students_parents',
    'teachers', 
    'schedules'
  ];

  // ============================================
  // FORMATAGE HEURE
  // ============================================

  static String _formatTimeToSupabase(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      throw FormatException('Heure vide ou null');
    }
    
    String s = value.toString().trim();
    print('🔍 _formatTimeToSupabase input: "$s"');

    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(s)) {
      print('✅ Format HH:MM:SS');
      return s;
    }

    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) {
      print('✅ Format HH:MM -> $s:00');
      return "$s:00";
    }

    if (RegExp(r'^\d{1}:\d{2}$').hasMatch(s)) {
      final padded = "0$s:00";
      print('✅ Format H:MM -> $padded');
      return padded;
    }

    final hMatch = RegExp(r'^(\d{1,2})[hH](\d{2})$').firstMatch(s);
    if (hMatch != null) {
      final result = "${hMatch.group(1)!.padLeft(2, '0')}:${hMatch.group(2)!}:00";
      print('✅ Format HeureMinute -> $result');
      return result;
    }

    if (RegExp(r'^\d{4}$').hasMatch(s)) {
      final result = "${s.substring(0, 2)}:${s.substring(2)}:00";
      print('✅ Format 4chiffres -> $result');
      return result;
    }

    if (s.contains(' ')) {
      final parts = s.split(' ');
      final timePart = parts.last;
      if (RegExp(r'^\d{2}:\d{2}(:\d{2})?$').hasMatch(timePart)) {
        final result = timePart.length == 5 ? "$timePart:00" : timePart;
        print('✅ Format datetime -> $result');
        return result;
      }
    }

    if (s.contains('T')) {
      final timePart = s.split('T')[1];
      final result = timePart.substring(0, 8);
      print('✅ Format ISO -> $result');
      return result;
    }

    if (RegExp(r'^\d+\.\d+$').hasMatch(s)) {
      try {
        final fraction = double.parse(s);
        if (fraction > 0 && fraction < 1) {
          final totalSeconds = (fraction * 24 * 60 * 60).round();
          final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
          final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
          final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
          final result = "$hours:$minutes:$seconds";
          print('✅ Format Excel fraction -> $result');
          return result;
        }
      } catch (_) {}
    }

    print('❌ Format non reconnu: "$s"');
    throw FormatException('Format d\'heure non reconnu: "$s"');
  }

  // ============================================
  // EXECUTION IMPORT - VERSION ORIGINALE CORRIGÉE
  // ============================================

  static Future<ImportResult> executeImport({
    required String type,
    required String schoolId,
    required String schoolCode,
    String? schoolYear,
    required List<Map<String, dynamic>> data,
  }) async {
    if (!validTypes.contains(type)) {
      return ImportResult(
        success: false,
        message: 'Type invalide: $type',
      );
    }

    if (data.isEmpty) {
      return ImportResult(success: false, message: 'Aucune donnée à importer');
    }

    try {
      final formattedData = data.map((row) {
        final Map<String, dynamic> cleanRow = Map<String, dynamic>.from(row);
        
        if (type == 'schedules') {
          final rawStart = cleanRow['heure_debut'] ?? cleanRow['heure_début'] ?? cleanRow['start_time'];
          final rawEnd = cleanRow['heure_fin'] ?? cleanRow['end_time'];
          
          cleanRow['start_time'] = _formatTimeToSupabase(rawStart);
          cleanRow['end_time'] = _formatTimeToSupabase(rawEnd);
          
          cleanRow.remove('heure_debut');
          cleanRow.remove('heure_début');
          cleanRow.remove('heure_fin');
        }
        
        cleanRow['school_id'] = schoolId;
        cleanRow['school_code'] = schoolCode;
        cleanRow['school_year'] = schoolYear ?? '2024-2025';
        
        return cleanRow;
      }).toList();

      print('📤 Envoi ${formattedData.length} lignes à $_functionUrl');

      // 🔥 VERSION ORIGINALE : Service Role Key dans Authorization
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Authorization': 'Bearer $_serviceRoleKey',  // ← TA VERSION ORIGINALE
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': type,
          'schoolId': schoolId,
          'schoolCode': schoolCode,
          'schoolYear': schoolYear ?? '2024-2025',
          'data': formattedData,
        }),
      ).timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw ImportTimeoutException('Le serveur a mis trop de temps à répondre'),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body.substring(0, response.body.length > 1000 ? 1000 : response.body.length)}');

      final responseData = jsonDecode(response.body);
      
      return ImportResult(
        success: responseData['success'] == true,
        created: responseData['created'] ?? 0,
        updated: responseData['updated'] ?? 0,
        deleted: responseData['deleted'] ?? 0,
        errors: (responseData['errors'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        credentials: (responseData['credentials'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        requestId: responseData['requestId'],
        duration: responseData['duration'],
        message: responseData['message'] ?? '${responseData['created'] ?? 0} créé(s), ${responseData['updated'] ?? 0} mis à jour',
      );

    } catch (e) {
      return ImportResult(success: false, message: 'Erreur: $e');
    }
  }

  // ============================================
  // PARSING FICHIER - VERSION CORRIGÉE EXCEL
  // ============================================

  static List<Map<String, dynamic>> parseFile(FilePickerResult pickerResult) {
    final file = pickerResult.files.first;
    final bytes = file.bytes ?? (file.path != null ? File(file.path!).readAsBytesSync() : null);

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Impossible de lire le fichier');
    }

    print('📁 Fichier: ${file.name}, extension: ${file.extension}, taille: ${bytes.length} bytes');

    if (file.extension == 'xlsx' || file.extension == 'xls') {
      return _readExcel(bytes);
    } else {
      return _readCsv(bytes);
    }
  }

  static List<Map<String, dynamic>> _readCsv(Uint8List bytes) {
    final csvString = _decodeWithFallback(bytes);
    final separator = _detectSeparator(csvString);
    final eol = csvString.contains('\r\n') ? '\r\n' : '\n';
    
    final rows = CsvToListConverter(
      fieldDelimiter: separator,
      eol: eol,
      shouldParseNumbers: false,
    ).convert(csvString);

    if (rows.length < 2) return [];

    final headers = rows.first.map((e) {
      return e.toString()
        .trim()
        .toLowerCase()
        .replaceAll('\ufeff', '')
        .replaceAll('\u00a0', '')
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('ô', 'o')
        .replaceAll('ê', 'e')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
    }).toList();

    print('📋 Headers nettoyés: $headers');

    return rows.skip(1)
        .where((row) => row.any((cell) => cell.toString().trim().isNotEmpty))
        .map((row) {
      final map = <String, dynamic>{};
      for (var i = 0; i < headers.length; i++) {
        if (i < row.length) {
          map[headers[i]] = row[i].toString().trim();
        }
      }
      return map;
    }).toList();
  }

  static List<Map<String, dynamic>> _readExcel(Uint8List bytes) {
    try {
      final excel = excel_lib.Excel.decodeBytes(bytes);
      List<Map<String, dynamic>> list = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;
        if (sheet.maxRows < 2) continue;

        final headers = sheet.rows.first.map((cell) => 
          _extractCellValue(cell)?.toString().trim().toLowerCase() ?? "").toList();

        for (int i = 1; i < sheet.maxRows; i++) {
          var row = sheet.rows[i];
          if (row.any((cell) => _extractCellValue(cell) != null)) {
            var map = <String, dynamic>{};
            for (int j = 0; j < headers.length; j++) {
              if (j < row.length) {
                final value = _extractCellValue(row[j]);
                map[headers[j]] = value?.toString().trim() ?? "";
              }
            }
            list.add(map);
          }
        }
        break;
      }
      return list;
    } catch (e) {
      throw Exception('Impossible de lire le fichier Excel: $e');
    }
  }

  // 🔥 EXTRACTEUR ULTRA-SIMPLE: toString() uniquement
  static dynamic _extractCellValue(dynamic cell) {
    if (cell == null) return null;
    try {
      final value = cell.value;
      if (value == null) return null;
      return value.toString();
    } catch (e) {
      return cell.toString();
    }
  }

  static String _decodeWithFallback(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return utf8.decode(bytes, allowMalformed: true);
      }
    }
  }

  static String _detectSeparator(String content) {
    if (content.isEmpty) return ',';
    final firstLine = content.split('\n').first;
    final semicolons = ';'.allMatches(firstLine).length;
    final commas = ','.allMatches(firstLine).length;
    return semicolons > commas ? ';' : ',';
  }
}

// ============================================
// CLASSES RÉSULTAT
// ============================================

class ImportResult {
  final bool success;
  final bool cancelled;
  final int created;
  final int updated;
  final int deleted;
  final int? processed;
  final int? total;
  final List<Map<String, dynamic>> errors;
  final List<Map<String, dynamic>> credentials;
  final String? requestId;
  final String? duration;
  final String message;
  final String? rawResponse;

  ImportResult({
    required this.success,
    this.cancelled = false,
    this.created = 0,
    this.updated = 0,
    this.deleted = 0,
    this.processed,
    this.total,
    this.errors = const [],
    this.credentials = const [],
    this.requestId,
    this.duration,
    this.message = '',
    this.rawResponse,
  });

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      success: json['success'] ?? false,
      created: json['created'] ?? 0,
      updated: json['updated'] ?? 0,
      deleted: json['deleted'] ?? 0,
      total: json['total'],
      errors: List<Map<String, dynamic>>.from(json['errors'] ?? []),
      credentials: List<Map<String, dynamic>>.from(json['credentials'] ?? []),
      message: json['message'] ?? '',
      requestId: json['requestId'],
      duration: json['duration'],
      rawResponse: json.toString(),
    );
  }

  bool get hasErrors => errors.isNotEmpty;
  bool get isPartialSuccess => success && hasErrors;
  int get errorCount => errors.length;

  @override
  String toString() {
    return 'ImportResult(success: $success, created: $created, updated: $updated, '
        'errors: ${errors.length}, message: $message)';
  }
}

class ImportTimeoutException implements Exception {
  final String message;
  ImportTimeoutException(this.message);
  @override
  String toString() => message;
}