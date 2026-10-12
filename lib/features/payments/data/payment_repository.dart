// lib/features/payments/data/payment_repository.dart

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/import_report.dart';
import '../models/payment_status_dto.dart';

class PaymentRepository {
  final SupabaseClient _client;

  PaymentRepository(this._client);

  // ── Import CSV ──────────────────────────────────────────────

  Future<ImportReport> importCsv({
    required String schoolId,
    required String csvContent,
    String? importedBy,
    bool simulate = false,
  }) async {
    final rows = _parseCsv(csvContent);
    return _importRows(schoolId, rows, importedBy, simulate: simulate);
  }

  // ── Import Excel (.xlsx) ────────────────────────────────────

  Future<ImportReport> importExcel({
    required String schoolId,
    required List<int> bytes,
    String? importedBy,
    bool simulate = false,
  }) async {
    final rows = _parseExcel(bytes);
    return _importRows(schoolId, rows, importedBy, simulate: simulate);
  }

  // ── Cœur de l'import (commun CSV / Excel) ───────────────────

  Future<ImportReport> _importRows(
    String schoolId,
    List<Map<String, String>> rows,
    String? importedBy, {
    bool simulate = false,
  }) async {
    final report = ImportReport();

    if (rows.isEmpty) {
      report.addGlobalError('Fichier vide ou invalide.');
      return report;
    }

    // 1. Étudiants de l'école par matricule (1 seule requête)
    final matricules = rows
        .map((r) => r['matricule']?.trim() ?? '')
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();

    if (matricules.isEmpty) {
      report.addGlobalError(
          'Aucun matricule trouvé dans le fichier. Vérifiez l\'en-tête.');
      return report;
    }

    final students = await _client
        .from('students')
        .select('id, matricule')
        .eq('school_id', schoolId)
        .filter('matricule', 'in', matricules);

    final byMatricule = <String, String>{};
    for (final s in students as List) {
      final m = s['matricule'];
      if (m != null) byMatricule[m as String] = s['id'] as String;
    }

    // 2. Validation ligne par ligne
    final validLines = <Map<String, dynamic>>[];
    final totalFees = <String, double>{};
    for (var i = 0; i < rows.length; i++) {
      final rowNum = i + 2; // header = ligne 1
      final r = rows[i];
      final matricule = r['matricule']?.trim() ?? '';

      // Contrôle 0 : matricule présent
      if (matricule.isEmpty) {
        report.reject(rowNum, '(vide)', 'Matricule manquant sur la ligne');
        continue;
      }

      // Contrôle 1 : matricule connu
      final studentId = byMatricule[matricule];
      if (studentId == null) {
        report.reject(rowNum, matricule, 'Matricule introuvable dans l\'école');
        continue;
      }

      // Contrôle 2 : période AAAA-MM
      final periode = (r['periode'] ?? '').trim();
      if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(periode)) {
        report.reject(rowNum, matricule,
            'Période invalide (format attendu : AAAA-MM, ex: 2026-10)');
        continue;
      }

      // Contrôle 3 : montants
      final amountDue = _parseAmount(r['montant_du']);
      final amountPaid = _parseAmount(r['montant_paye']);
      if (amountDue == null || amountPaid == null) {
        report.reject(rowNum, matricule, 'Montant invalide (attendu : nombre)');
        continue;
      }

      // Contrôle 3b : surpaiement AUTORISÉ (avance du parent).
      // Seul un dépassement du MONTANT TOTAL de la scolarité est rejeté.
      final totalFeeFile = _parseAmount(r['montant_total']);
      if (totalFeeFile != null && amountPaid > totalFeeFile) {
        report.reject(
            rowNum,
            matricule,
            'Montant payé ($amountPaid) supérieur au montant total '
            'de la scolarité (${totalFeeFile.toStringAsFixed(0)} F)');
        continue;
      }

      // Contrôle 4 : date de paiement (ISO ou JJ/MM/AAAA)
      final paidAt = _parseDate(r['date_paiement']);
      if ((r['date_paiement'] ?? '').trim().isNotEmpty && paidAt == null) {
        report.reject(rowNum, matricule,
            'Date de paiement invalide (formats : AAAA-MM-JJ ou JJ/MM/AAAA)');
        continue;
      }

      // Contrôle 5 : date d'échéance (optionnelle)
      final dueDate = _parseDate(r['date_echeance']);
      if ((r['date_echeance'] ?? '').trim().isNotEmpty && dueDate == null) {
        report.reject(rowNum, matricule,
            'Date d\'échéance invalide (formats : AAAA-MM-JJ ou JJ/MM/AAAA)');
        continue;
      }

      // Contrôle 6 : montant total global (optionnel)
      final totalFee = _parseAmount(r['montant_total']);
      if (totalFee != null) totalFees[studentId] = totalFee;

      validLines.add({
        'school_id': schoolId,
        'student_id': studentId,
        'periode': periode,
        'libelle': (r['libelle'] ?? '').trim(),
        'amount_due': amountDue,
        'amount_paid': amountPaid,
        'paid_at': paidAt,
        'due_date': dueDate,
        'source': 'import',
        'updated_at': DateTime.now().toIso8601String(),
      });
      report.accept();
    }

    if (validLines.isEmpty) return report;

    // VERROU : abandon si plus de la moitié des lignes rejetées (mode réel)
    if (!simulate && report.rejectedRows * 2 > rows.length) {
      report.addGlobalError(
          'Import ANNULÉ : plus de la moitié des lignes sont rejetées. '
          'Vérifiez le fichier (matricules, colonnes) avant de réessayer.');
      return report;
    }

    // MODE SIMULATION : validation seule, aucune écriture
    if (simulate) return report;

    // 3. Journaliser l'import
    final importRow = await _client
        .from('payment_imports')
        .insert({
          'school_id': schoolId,
          'imported_by': importedBy,
          'total_rows': rows.length,
          'accepted_rows': report.acceptedRows,
          'rejected_rows': report.rejectedRows,
          'errors': report.errorsJson,
        })
        .select('id')
        .single();
    final importId = importRow['id'] as String;

    // 4. Upsert des lignes (idempotent)
    final affectedStudents = <String>{};
    for (final line in validLines) {
      line['import_id'] = importId;
      await _client.from('student_payment_lines').upsert(
            line,
            onConflict: 'student_id,periode,libelle',
          );
      affectedStudents.add(line['student_id'] as String);
    }

    // 5. Recalcul du statut courant par étudiant touché
    for (final studentId in affectedStudents) {
      await _recalcStatus(schoolId, studentId, totalFee: totalFees[studentId]);
    }

    // 5b. Compteurs pour le pilotage de CET import
    final counts = await _client
        .from('student_payment_status')
        .select('is_up_to_date')
        .eq('school_id', schoolId)
        .filter('student_id', 'in', affectedStudents.toList());
    var okCount = 0, lateCount = 0;
    for (final c in counts as List) {
      if (c['is_up_to_date'] == true) {
        okCount++;
      } else {
        lateCount++;
      }
    }
    await _client.from('payment_imports').update({
      'up_to_date_count': okCount,
      'late_count': lateCount,
    }).eq('id', importId);

    // 6. Notifier les parents (alerte persistante jusqu'au clic)
    await createPaymentNotifications(affectedStudents);

    return report;
  }

  Future<void> _recalcStatus(String schoolId, String studentId,
      {double? totalFee}) async {
    final lines = await _client
        .from('student_payment_lines')
        .select('amount_due, amount_paid, periode')
        .eq('student_id', studentId);

    var totalDue = 0.0;
    var totalPaid = 0.0;
    final currentPeriod = _currentPeriod();
    var upToDate = true;

    for (final l in lines as List) {
      totalDue += (l['amount_due'] as num).toDouble();
      totalPaid += (l['amount_paid'] as num).toDouble();
      if ((l['periode'] as String).compareTo(currentPeriod) <= 0 &&
          (l['amount_paid'] as num) < (l['amount_due'] as num)) {
        upToDate = false;
      }
    }

    await _client.from('student_payment_status').upsert({
      'school_id': schoolId,
      'student_id': studentId,
      'amount_due': totalDue,
      'amount_paid': totalPaid,
      if (totalFee != null) 'total_fee': totalFee,
      'is_up_to_date': upToDate,
      'contested': false,
      'last_import_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'student_id');
  }

  // ── Lecture admin ───────────────────────────────────────────

  Future<List<PaymentStatusDto>> getStatusByClass(String schoolId) async {
    final statusRows = await _client
        .from('student_payment_status')
        .select()
        .eq('school_id', schoolId)
        .order('updated_at', ascending: false);

    if ((statusRows as List).isEmpty) return [];

    final studentIds =
        statusRows.map((e) => e['student_id'] as String).toSet().toList();

    final studentRows = await _client
        .from('students')
        .select('id, first_name, last_name, matricule, class_id')
        .filter('id', 'in', studentIds);

    final byId = <String, Map<String, dynamic>>{};
    for (final s in studentRows as List) {
      byId[s['id'] as String] = Map<String, dynamic>.from(s);
    }

    return statusRows.map((e) {
      final map = Map<String, dynamic>.from(e);
      final s = byId[map['student_id']] ?? {};
      map['students'] = {
        'nom': s['last_name'] ?? '',
        'prenom': s['first_name'] ?? '',
        'matricule': s['matricule'] ?? '',
        'class_id': s['class_id'] ?? '',
      };
      return PaymentStatusDto.fromJson(map);
    }).toList();
  }

  Future<Map<String, dynamic>> getDashboardStats(String schoolId) async {
    final rows = await _client
        .from('student_payment_status')
        .select('amount_due, amount_paid, is_up_to_date')
        .eq('school_id', schoolId);

    var ok = 0, late = 0;
    var totalDue = 0.0, totalPaid = 0.0;
    for (final r in rows as List) {
      if (r['is_up_to_date'] == true) {
        ok++;
      } else {
        late++;
      }
      totalDue += (r['amount_due'] as num?)?.toDouble() ?? 0;
      totalPaid += (r['amount_paid'] as num?)?.toDouble() ?? 0;
    }

    return {
      'total': ok + late,
      'upToDate': ok,
      'late': late,
      'amountDue': totalDue,
      'amountPaid': totalPaid,
      'remaining': totalDue - totalPaid,
    };
  }

  Future<List<Map<String, dynamic>>> getImportHistory(String schoolId,
      {int limit = 15}) async {
    final rows = await _client
        .from('payment_imports')
        .select(
            'id, total_rows, accepted_rows, rejected_rows, up_to_date_count, late_count, created_at')
        .eq('school_id', schoolId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> getContested(String schoolId) async {
    final rows = await _client
        .from('student_payment_status')
        .select()
        .eq('school_id', schoolId)
        .eq('contested', true)
        .order('contested_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, String>> getClassNames(String schoolId) async {
    final rows = await _client
        .from('classes')
        .select('id, name')
        .eq('school_id', schoolId);
    return {
      for (final c in rows as List)
        c['id'] as String: c['name'] as String? ?? ''
    };
  }

  Future<int> countLateStudents(String schoolId) async {
    final rows = await _client
        .from('student_payment_status')
        .select('id')
        .eq('school_id', schoolId)
        .eq('is_up_to_date', false);
    return (rows as List).length;
  }

  Future<bool> getGradeGatingEnabled(String schoolId) async {
    final row = await _client
        .from('schools')
        .select('grade_gating_enabled')
        .eq('id', schoolId)
        .single();
    return row['grade_gating_enabled'] as bool? ?? false;
  }

  Future<void> setGradeGatingEnabled(String schoolId, bool enabled) async {
    await _client
        .from('schools')
        .update({'grade_gating_enabled': enabled}).eq('id', schoolId);
  }

  Future<void> setStudentUpToDate(
      String schoolId, String studentId, bool upToDate) async {
    await _client.from('student_payment_status').upsert({
      'school_id': schoolId,
      'student_id': studentId,
      'is_up_to_date': upToDate,
      'source': 'manual',
      'contested': false,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'student_id');
  }

  // ── Parent ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyChildren(String parentId) async {
    final links = await _client
        .from('parent_students')
        .select('student_id')
        .eq('parent_id', parentId);

    final ids = (links as List).map((e) => e['student_id'] as String).toList();
    if (ids.isEmpty) return [];

    final students = await _client
        .from('students')
        .select('id, first_name, last_name, matricule')
        .filter('id', 'in', ids);

    return List<Map<String, dynamic>>.from(students as List);
  }

  Future<Map<String, dynamic>?> getMyChildStatus(String studentId) async {
    final rows = await _client
        .from('student_payment_status')
        .select('*')
        .eq('student_id', studentId)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : Map<String, dynamic>.from(list.first);
  }

  Future<List<Map<String, dynamic>>> getMyChildLines(String studentId) async {
    final rows = await _client
        .from('student_payment_lines')
        .select(
            'id, periode, libelle, amount_due, amount_paid, paid_at, due_date')
        .eq('student_id', studentId)
        .order('periode', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> contestStatus(String statusId, String message) async {
    await _client.from('student_payment_status').update({
      'contested': true,
      'contested_at': DateTime.now().toIso8601String(),
      'contested_message': message,
    }).eq('id', statusId);
  }

  // ── Notifications scolarité (parent) ────────────────────────

  Future<void> createPaymentNotifications(Set<String> studentIds) async {
    if (studentIds.isEmpty) return;
    await _client.from('student_notifications').insert(
          studentIds
              .map((id) => {
                    'student_id': id,
                    'type': 'payment_update',
                    'message':
                        'La situation de scolarité de votre enfant a été mise à jour. Consultez l\'onglet Comptabilité.',
                  })
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getUnreadPaymentNotifications(
      String studentId) async {
    final rows = await _client
        .from('student_notifications')
        .select('id, message, created_at')
        .eq('student_id', studentId)
        .eq('type', 'payment_update')
        .isFilter('read_at', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> markPaymentNotificationsRead(String studentId) async {
    await _client
        .from('student_notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('student_id', studentId)
        .eq('type', 'payment_update')
        .isFilter('read_at', null);
  }

  // ── Saisie manuelle & relances ──────────────────────────────

  Future<void> addManualPayment({
    required String schoolId,
    required String studentId,
    required String periode,
    required String libelle,
    required double amountPaid,
    double? amountDue,
    String? paidAt,
  }) async {
    final existing = await _client
        .from('student_payment_lines')
        .select('id, amount_due, amount_paid')
        .eq('student_id', studentId)
        .eq('periode', periode)
        .limit(1);

    final list = existing as List;

    if (list.isNotEmpty) {
      // Addition au paiement existant (aucun doublon)
      final row = list.first;
      final newPaid =
          ((row['amount_paid'] as num?)?.toDouble() ?? 0) + amountPaid;
      await _client.from('student_payment_lines').update({
        'amount_paid': newPaid,
        if (paidAt != null) 'paid_at': paidAt,
        'source': 'manual',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', row['id'] as String);
    } else {
      await _client.from('student_payment_lines').insert({
        'school_id': schoolId,
        'student_id': studentId,
        'periode': periode,
        'libelle': libelle,
        'amount_due': amountDue ?? amountPaid,
        'amount_paid': amountPaid,
        'paid_at': paidAt ?? DateTime.now().toIso8601String().substring(0, 10),
        'source': 'manual',
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    await _recalcStatus(schoolId, studentId);
    await createPaymentNotifications({studentId});
  }

  Future<List<Map<String, dynamic>>> getStudentLinesAdmin(
      String studentId) async {
    final rows = await _client
        .from('student_payment_lines')
        .select(
            'id, periode, libelle, amount_due, amount_paid, paid_at, due_date, source, created_at')
        .eq('student_id', studentId)
        .order('periode', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> getLateStudentsWithParents(
      String schoolId) async {
    final lateRows = await _client
        .from('student_payment_status')
        .select('student_id, amount_due, amount_paid')
        .eq('school_id', schoolId)
        .eq('is_up_to_date', false);

    final studentIds = (lateRows as List)
        .map((e) => e['student_id'] as String)
        .toSet()
        .toList();
    if (studentIds.isEmpty) return [];

    final students = await _client
        .from('students')
        .select('id, first_name, last_name, matricule, class_id')
        .filter('id', 'in', studentIds);

    final links = await _client
        .from('parent_students')
        .select('student_id, parent_id')
        .filter('student_id', 'in', studentIds);

    final parentIds =
        (links as List).map((e) => e['parent_id'] as String).toSet().toList();

    final parents = parentIds.isEmpty
        ? <dynamic>[]
        : await _client
            .from('app_users')
            .select('id, first_name, last_name, phone')
            .filter('id', 'in', parentIds);

    final classes = await _client
        .from('classes')
        .select('id, name')
        .eq('school_id', schoolId);

    final classNameById = <String, String>{
      for (final c in classes as List)
        c['id'] as String: c['name'] as String? ?? ''
    };
    final parentById = <String, Map<String, dynamic>>{};
    for (final p in parents as List) {
      parentById[p['id'] as String] = Map<String, dynamic>.from(p);
    }
    final studentById = <String, Map<String, dynamic>>{};
    for (final s in students as List) {
      studentById[s['id'] as String] = Map<String, dynamic>.from(s);
    }
    final linkByStudent = <String, String>{};
    for (final l in links as List) {
      linkByStudent[l['student_id'] as String] = l['parent_id'] as String;
    }
    final lateByStudent = <String, Map<String, dynamic>>{};
    for (final l in lateRows as List) {
      lateByStudent[l['student_id'] as String] = Map<String, dynamic>.from(l);
    }

    final result = <Map<String, dynamic>>[];
    for (final sid in studentIds) {
      final stu = studentById[sid];
      if (stu == null) continue;
      final pid = linkByStudent[sid];
      final par = pid != null ? parentById[pid] : null;
      final late = lateByStudent[sid] ?? {};
      final due = (late['amount_due'] as num?)?.toDouble() ?? 0;
      final paid = (late['amount_paid'] as num?)?.toDouble() ?? 0;
      final classId = stu['class_id'] as String? ?? '';
      result.add({
        'student_id': sid,
        'student_name': '${stu['first_name']} ${stu['last_name']}',
        'matricule': stu['matricule'] ?? '',
        'remaining': due - paid,
        'parent_id': pid,
        'parent_name': par != null
            ? '${par['first_name']} ${par['last_name']}'
            : 'Parent non lié',
        'parent_phone': par?['phone'] ?? '',
        'class_id': classId,
        'class_name': classNameById[classId] ?? 'Sans classe',
      });
    }
    result.sort((a, b) =>
        (b['remaining'] as double).compareTo(a['remaining'] as double));
    return result;
  }

  Future<Map<String, Map<String, dynamic>>> getRelanceSummary(
      String schoolId, List<String> parentIds) async {
    if (parentIds.isEmpty) return {};
    final since =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final rows = await _client
        .from('admin_messages')
        .select('target_parent_id, created_at')
        .eq('school_id', schoolId)
        .eq('sender_name', 'Comptabilité')
        .filter('target_parent_id', 'in', parentIds)
        .gte('created_at', since);
    final result = <String, Map<String, dynamic>>{};
    for (final r in rows as List) {
      final pid = r['target_parent_id'] as String?;
      if (pid == null) continue;
      final entry = result.putIfAbsent(pid, () => {'count': 0, 'lastAt': null});
      entry['count'] = (entry['count'] as int) + 1;
      final at = r['created_at'] as String?;
      if (at != null &&
          (entry['lastAt'] == null || at.compareTo(entry['lastAt']) > 0)) {
        entry['lastAt'] = at;
      }
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getRelanceHistory(String parentId) async {
    final rows = await _client
        .from('admin_messages')
        .select('id, title, content, created_at')
        .eq('target_parent_id', parentId)
        .eq('sender_name', 'Comptabilité')
        .order('created_at', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  // ── Helpers ─────────────────────────────────────────────────

  List<Map<String, String>> _parseCsv(String content) {
    final clean = content.replaceAll('﻿', '');
    final firstLine = clean.split(RegExp(r'\r?\n')).first;
    final delimiter = firstLine.contains(';') ? ';' : ',';

    final table = CsvToListConverter(
      fieldDelimiter: delimiter,
      shouldParseNumbers: false,
    ).convert(clean);

    if (table.length < 2) return [];

    final headers =
        table.first.map((h) => h.toString().trim().toLowerCase()).toList();
    final result = <Map<String, String>>[];
    for (var i = 1; i < table.length; i++) {
      final cells = table[i];
      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < cells.length; j++) {
        row[headers[j]] = cells[j].toString().trim();
      }
      if (row.values.any((v) => v.isNotEmpty)) result.add(row);
    }
    return result;
  }

  List<Map<String, String>> _parseExcel(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    final sheet = excel.tables.values.first;
    if (sheet.rows.length < 2) return [];

    final headers = sheet.rows.first
        .map((c) => (c?.value ?? '').toString().trim().toLowerCase())
        .toList();

    final result = <Map<String, String>>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final cells = sheet.rows[i];
      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < cells.length; j++) {
        if (headers[j].isEmpty) continue;
        row[headers[j]] = (cells[j]?.value ?? '').toString().trim();
      }
      if (row.values.any((v) => v.isNotEmpty)) result.add(row);
    }
    return result;
  }

  double? _parseAmount(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.replaceAll(' ', '').replaceAll(',', '.'));
  }

  String? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = raw.trim();
    final iso = DateTime.tryParse(v);
    if (iso != null) return v;
    final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(v);
    if (m != null) return '${m[3]}-${m[2]}-${m[1]}';
    return null;
  }

  String _currentPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
