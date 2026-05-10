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
  
  static String get _serviceRoleKey => 
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  static const List<String> validTypes = [
    'students_parents',
    'teachers', 
    'schedules'
  ];

  static String _formatTimeToSupabase(dynamic value) {
    if (value == null || value.toString().isEmpty) return "00:00:00";
    String s = value.toString().trim();
    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(s)) return s;
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) return "$s:00";
    if (s.contains(' ')) {
      String timePart = s.split(' ')[1];
      return timePart.length == 5 ? "$timePart:00" : timePart;
    }
    return s;
  }

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

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Authorization': 'Bearer $_serviceRoleKey',
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

  static List<Map<String, dynamic>> parseFile(FilePickerResult pickerResult) {
    final file = pickerResult.files.first;
    final bytes = file.bytes ?? (file.path != null ? File(file.path!).readAsBytesSync() : null);

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Impossible de lire le fichier');
    }

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

    final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

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
    var excel = excel_lib.Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> list = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;
      if (sheet.maxRows < 2) continue;

      final headers = sheet.rows.first.map((cell) => 
        cell?.value.toString().trim().toLowerCase() ?? "").toList();

      for (int i = 1; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        if (row.any((cell) => cell?.value != null)) {
          var map = <String, dynamic>{};
          for (int j = 0; j < headers.length; j++) {
            if (j < row.length) {
              map[headers[j]] = row[j]?.value.toString().trim() ?? "";
            }
          }
          list.add(map);
        }
      }
      break;
    }
    return list;
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
        'deleted: $deleted, errors: ${errors.length}, credentials: ${credentials.length}, message: $message)';
  }
}

class ImportTimeoutException implements Exception {
  final String message;
  ImportTimeoutException(this.message);
  @override
  String toString() => message;
}