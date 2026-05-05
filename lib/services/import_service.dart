import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImportService {
  static final client = Supabase.instance.client;

  static Future<void> executeFullImport({
    required String type, // 'teachers', 'students_parents', 'schedules'
    required String schoolId,
    required String schoolCode,
    required String schoolYear,
  }) async {
    // 1. Sélection et lecture du fichier
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result == null) return;

    var bytes = File(result.files.single.path!).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> jsonData = [];

    // 2. Parsing Excel vers JSON
    for (var table in excel.tables.keys) {
      var rows = excel.tables[table]?.rows;
      if (rows == null || rows.length < 2) continue;

      var headers = rows[0].map((e) => e?.value.toString().toLowerCase().trim()).toList();

      for (int i = 1; i < rows.length; i++) {
        Map<String, dynamic> rowData = {};
        for (int j = 0; j < headers.length; j++) {
          rowData[headers[j]!] = rows[i][j]?.value;
        }
        jsonData.add(rowData);
      }
    }

    // 3. Appel à ta Edge Function existante
    await client.functions.invoke(
      'bulk-import', // Nom de ta fonction Deno
      body: {
        'type': type,
        'data': jsonData,
        'schoolId': schoolId,
        'schoolCode': schoolCode,
        'schoolYear': schoolYear,
      },
    );
  }
}