import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImportService {
  static final client = Supabase.instance.client;

  // Retourne la réponse brute de la fonction (ou null si annulé)
  static Future<dynamic> executeFullImport({
    required String type,
    required String schoolId,
    required String schoolCode,
    required String schoolYear,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true, // AJOUT : bytes disponibles même si path == null
    );

    if (result == null) return null;

    List<Map<String, dynamic>> jsonData = [];

    // ---- PARSING (instrumenté) ----
    try {
      final picked = result.files.single;
      var bytes = picked.bytes ?? File(picked.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      for (var table in excel.tables.keys) {
        var rows = excel.tables[table]?.rows;
        if (rows == null || rows.length < 2) continue;

        // FIX null : e?.value?.toString() chaîne complète
        var headers = rows[0]
            .map((e) => e?.value?.toString().toLowerCase().trim())
            .toList();

        for (int i = 1; i < rows.length; i++) {
          Map<String, dynamic> rowData = {};
          // FIX débordement : borne par la ligne ET ignore en-têtes nulls
          int limit =
              rows[i].length < headers.length ? rows[i].length : headers.length;
          for (int j = 0; j < limit; j++) {
            final h = headers[j];
            if (h == null) continue;
            rowData[h] = rows[i][j]?.value;
          }
          if (rowData.values.any((v) => v != null)) jsonData.add(rowData);
        }
      }
      print('✅ PARSING OK [$type] : ${jsonData.length} lignes');
    } catch (e, st) {
      print('❌ CRASH PENDANT LE PARSING : $e\n$st');
      throw Exception('Erreur lecture fichier: $e');
    }

    // ---- APPEL FONCTION (instrumenté) ----
    try {
      final res = await client.functions.invoke(
        'bulk-import',
        body: {
          'type': type,
          'data': jsonData,
          'schoolId': schoolId,
          'schoolCode': schoolCode,
          'schoolYear': schoolYear,
        },
      );
      print('✅ RÉPONSE bulk-import : ${res.data}');
      return res.data;
    } on FunctionException catch (e) {
      print('❌ ERREUR FONCTION HTTP ${e.status} : ${e.details}');
      throw Exception('Fonction bulk-import: ${e.details}');
    }
  }
}
