// lib/services/bulk_import_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class BulkImportService {
  static const String _functionUrl = 
      'https://vethtvfdkywbzxzwckdl.supabase.co/functions/v1/bulk-import';
  
  static const String _serviceRoleKey = 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZldGh0dmZka3l3Ynp4endja2RsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTcyNTY4NCwiZXhwIjoyMDkxMzAxNjg0fQ.T5UwEMr4bOr8zfylJX1fbSnSq1gwWuufq-gA94UQR-Q';

  static const List<String> validTypes = [
    'students_parents',
    'teachers', 
    'schedules'
  ];

  static Future<ImportResult> importFromCsv({
    required String type,
    required String schoolId,
    required String schoolCode,
    String? schoolYear,
    FilePickerResult? fileResult,
  }) async {
    if (!validTypes.contains(type)) {
      return ImportResult(
        success: false,
        message: 'Type invalide: $type. Types valides: ${validTypes.join(", ")}',
      );
    }

    FilePickerResult? pickerResult = fileResult;
    pickerResult ??= await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
      dialogTitle: 'Sélectionner un fichier CSV',
    );

    if (pickerResult == null) {
      return ImportResult(
        success: false, 
        cancelled: true, 
        message: 'Aucun fichier sélectionné',
      );
    }

    try {
      final bytes = pickerResult.files.first.bytes;
      final path = pickerResult.files.first.path;
      
      Uint8List? fileBytes;
      if (bytes != null) {
        fileBytes = bytes;
      } else if (path != null) {
        fileBytes = await File(path).readAsBytes();
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        return ImportResult(
          success: false, 
          message: 'Impossible de lire le fichier',
        );
      }

      final csvString = _decodeWithFallback(fileBytes);
      final separator = _detectSeparator(csvString);
      final eol = csvString.contains('\r\n') ? '\r\n' : '\n';
      
      final rows = CsvToListConverter(
        fieldDelimiter: separator,
        eol: eol,
        shouldParseNumbers: false,
      ).convert(csvString);

      if (rows.isEmpty || rows.length < 2) {
        return ImportResult(
          success: false, 
          message: 'Fichier CSV vide',
        );
      }

      final headers = rows.first
          .map((e) => e.toString().trim())
          .where((h) => h.isNotEmpty)
          .toList();

      final data = rows.skip(1)
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
          'data': data,
        }),
      ).timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw ImportTimeoutException('Timeout'),
      );

      final responseData = jsonDecode(response.body);
      
      return ImportResult(
        success: responseData['success'] == true,
        created: responseData['created'] ?? 0,
        updated: responseData['updated'] ?? 0,
        deleted: responseData['deleted'] ?? 0,
        errors: (responseData['errors'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        requestId: responseData['requestId'],
        duration: responseData['duration'],
        message: '${responseData['created'] ?? 0} créé(s), ${responseData['updated'] ?? 0} mis à jour',
      );

    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Erreur: $e',
      );
    }
  }

  static String _decodeWithFallback(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException catch (_) {
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
    this.requestId,
    this.duration,
    this.message = '',
    this.rawResponse,
  });

  // GETTERS AJOUTÉS :
  bool get hasErrors => errors.isNotEmpty;
  bool get isPartialSuccess => success && hasErrors;
  int get errorCount => errors.length;

  @override
  String toString() {
    return 'ImportResult(success: $success, created: $created, updated: $updated, '
        'deleted: $deleted, errors: ${errors.length}, message: $message)';
  }
}

class ImportTimeoutException implements Exception {
  final String message;
  ImportTimeoutException(this.message);
  @override
  String toString() => message;
}
