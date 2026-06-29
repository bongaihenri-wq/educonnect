// lib/presentation/blocs/school_report/school_report_bloc.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'school_report_event.dart';
import 'school_report_state.dart';

class SchoolReportBloc extends Bloc<SchoolReportEvent, SchoolReportState> {
  final _supabase = Supabase.instance.client;
  static const int _pageSize = 50;

  SchoolReportBloc() : super(SchoolReportInitial()) {
    on<LoadSchoolReportRequested>(_onLoadReport);
    on<LoadMoreReportRequested>(_onLoadMore);
    on<ExportSchoolReportRequested>(_onExportReport);
  }

  Future<void> _onLoadReport(
    LoadSchoolReportRequested event,
    Emitter<SchoolReportState> emit,
  ) async {
    emit(SchoolReportLoading());

    try {
      final attendanceData = await _loadAttendanceData(
        event.schoolId,
        event.periodId,
        event.startDate,
        event.endDate,
        event.classId,
        event.studentId,
        event.subjectId,
        event.teacherId,
        page: 0,
      );

      final gradesData = await _loadGradesData(
        event.schoolId,
        event.periodId,
        event.startDate,
        event.endDate,
        event.classId,
        event.studentId,
        event.subjectId,
        event.teacherId,
        page: 0,
      );

      final summaryStats = _calculateSummary(attendanceData, gradesData);

      emit(SchoolReportLoaded(
        attendanceData: attendanceData,
        gradesData: gradesData,
        summaryStats: summaryStats,
        hasMoreAttendance: attendanceData.length >= _pageSize,
        hasMoreGrades: gradesData.length >= _pageSize,
        currentPage: 0,
      ));
    } catch (e, stackTrace) {
      print('❌ Erreur chargement rapport: $e');
      print(stackTrace);
      emit(SchoolReportError('Erreur chargement rapport: $e'));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreReportRequested event,
    Emitter<SchoolReportState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SchoolReportLoaded) return;

    emit(SchoolReportLoadingMore(
      attendanceData: currentState.attendanceData,
      gradesData: currentState.gradesData,
      summaryStats: currentState.summaryStats,
      isLoadingAttendance: event.reportType == 'attendance',
      isLoadingGrades: event.reportType == 'grades',
    ));

    try {
      final nextPage = currentState.currentPage + 1;
      List<Map<String, dynamic>> newAttendance = [];
      List<Map<String, dynamic>> newGrades = [];

      if (event.reportType == 'attendance') {
        newAttendance = await _loadAttendanceData(
          event.schoolId,
          event.periodId,
          event.startDate,
          event.endDate,
          event.classId,
          event.studentId,
          event.subjectId,
          event.teacherId,
          page: nextPage,
        );
      } else {
        newGrades = await _loadGradesData(
          event.schoolId,
          event.periodId,
          event.startDate,
          event.endDate,
          event.classId,
          event.studentId,
          event.subjectId,
          event.teacherId,
          page: nextPage,
        );
      }

      final allAttendance = [...currentState.attendanceData, ...newAttendance];
      final allGrades = [...currentState.gradesData, ...newGrades];
      final summaryStats = _calculateSummary(allAttendance, allGrades);

      emit(SchoolReportLoaded(
        attendanceData: allAttendance,
        gradesData: allGrades,
        summaryStats: summaryStats,
        hasMoreAttendance: newAttendance.length >= _pageSize,
        hasMoreGrades: newGrades.length >= _pageSize,
        currentPage: nextPage,
      ));
    } catch (e, stackTrace) {
      print('❌ Erreur load more: $e');
      print(stackTrace);
      emit(SchoolReportError('Erreur chargement: $e'));
    }
  }

  Future<List<Map<String, dynamic>>> _loadAttendanceData(
    String schoolId,
    String? periodId,
    String? startDate,
    String? endDate,
    String? classId,
    String? studentId,
    String? subjectId,
    String? teacherId, {
    required int page,
  }) async {
    var query = _supabase.from('attendance').select('''
      id,
      date,
      status,
      student_id,
      students(id, first_name, last_name, matricule),
      schedules(start_time, end_time, subjects(name), classes(level, name), teacher_id),
      teachers:app_users!attendance_teacher_id_fkey(first_name, last_name)
    ''');

    query = query.eq('school_id', schoolId);

    if (periodId != null) {
      // Période académique : chercher par id
      print('📅 Filtre période par ID: $periodId');
      final period = await _supabase
          .from('school_trimester_definitions')
          .select('start_date, end_date')
          .eq('id', periodId)
          .single();

      final periodStart = period['start_date'] as String?;
      final periodEnd = period['end_date'] as String?;

      if (periodStart != null) {
        final startDateOnly = periodStart.split('T')[0];
        query = query.gte('date', startDateOnly);
        print('   Filtre gte: $startDateOnly');
      }
      if (periodEnd != null) {
        final endDateOnly = periodEnd.split('T')[0];
        query = query.lte('date', endDateOnly);
        print('   Filtre lte: $endDateOnly');
      }
    } else if (startDate != null && endDate != null) {
      // Période dynamique : utiliser les dates directement
      print('📅 Filtre période par dates: $startDate → $endDate');
      query = query.gte('date', startDate);
      query = query.lte('date', endDate);
    } else {
      print('📅 Aucun filtre période');
    }

    if (classId != null) query = query.eq('schedules.class_id', classId);
    if (studentId != null) query = query.eq('student_id', studentId);
    if (subjectId != null) query = query.eq('schedules.subject_id', subjectId);
    if (teacherId != null) query = query.eq('schedules.teacher_id', teacherId);

    final response = await query
        .order('date', ascending: false)
        .range(page * _pageSize, (page + 1) * _pageSize - 1);

    print('📅 Résultat attendance: ${response.length} enregistrements');
    if (response.isNotEmpty) {
      print('   Première date: ${response.first['date']}');
      print('   Dernière date: ${response.last['date']}');
    }

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _loadGradesData(
    String schoolId,
    String? periodId,
    String? startDate,
    String? endDate,
    String? classId,
    String? studentId,
    String? subjectId,
    String? teacherId, {
    required int page,
  }) async {
    var query = _supabase.from('grades').select('''
      id,
      score,
      max_score,
      coefficient,
      date,
      student_id,
      students(id, first_name, last_name, matricule),
      subjects(name),
      classes(level, name),
      teacher_id
    ''');

    query = query.eq('school_id', schoolId);

    if (periodId != null) {
      // Période académique : chercher par id
      print('📅 Filtre période grades par ID: $periodId');
      final period = await _supabase
          .from('school_trimester_definitions')
          .select('start_date, end_date')
          .eq('id', periodId)
          .single();

      final periodStart = period['start_date'] as String?;
      final periodEnd = period['end_date'] as String?;

      if (periodStart != null) {
        final startDateOnly = periodStart.split('T')[0];
        query = query.gte('date', startDateOnly);
        print('   Filtre gte: $startDateOnly');
      }
      if (periodEnd != null) {
        final endDateOnly = periodEnd.split('T')[0];
        query = query.lte('date', endDateOnly);
        print('   Filtre lte: $endDateOnly');
      }
    } else if (startDate != null && endDate != null) {
      // Période dynamique : utiliser les dates directement
      print('📅 Filtre période grades par dates: $startDate → $endDate');
      query = query.gte('date', startDate);
      query = query.lte('date', endDate);
    } else {
      print('📅 Aucun filtre période grades');
    }

    if (classId != null) query = query.eq('class_id', classId);
    if (studentId != null) query = query.eq('student_id', studentId);
    if (subjectId != null) query = query.eq('subject_id', subjectId);
    if (teacherId != null) query = query.eq('teacher_id', teacherId);

    final response = await query
        .order('date', ascending: false)
        .range(page * _pageSize, (page + 1) * _pageSize - 1);

    print('📅 Résultat grades: ${response.length} enregistrements');
    if (response.isNotEmpty) {
      print('   Première date: ${response.first['date']}');
      print('   Dernière date: ${response.last['date']}');
    }

    return List<Map<String, dynamic>>.from(response);
  }

  Map<String, dynamic> _calculateSummary(
    List<Map<String, dynamic>> attendance,
    List<Map<String, dynamic>> grades,
  ) {
    int totalPresent = 0;
    int totalAbsent = 0;
    int totalLate = 0;
    double totalGrade = 0;
    int gradeCount = 0;

    for (final a in attendance) {
      final status = a['status'] as String?;
      if (status == 'present') totalPresent++;
      if (status == 'absent') totalAbsent++;
      if (status == 'late') totalLate++;
    }

    for (final g in grades) {
      final score = (g['score'] as num?)?.toDouble() ?? 0;
      final maxScore = (g['max_score'] as num?)?.toDouble() ?? 20;
      final noteSur20 = maxScore > 0 ? (score / maxScore) * 20 : 0;
      totalGrade += noteSur20;
      gradeCount++;
    }

    final totalAttendance = attendance.length;
    final presenceRate = totalAttendance > 0
        ? (totalPresent / totalAttendance * 100).toStringAsFixed(1)
        : '0';

    return {
      'total_students': _extractUniqueCount(attendance, 'students'),
      'total_classes': _extractUniqueCount(attendance, 'schedules', 'classes'),
      'total_teachers': _extractUniqueCount(attendance, 'teachers'),
      'total_present': totalPresent,
      'total_absent': totalAbsent,
      'total_late': totalLate,
      'presence_rate': presenceRate,
      'average_grade': gradeCount > 0 ? (totalGrade / gradeCount).toStringAsFixed(2) : '0',
      'total_grades': gradeCount,
    };
  }

  int _extractUniqueCount(
    List<Map<String, dynamic>> data,
    String key, [
    String? subKey,
  ]) {
    final ids = <dynamic>{};
    for (final item in data) {
      dynamic value;
      if (subKey != null) {
        final nested = item[key];
        if (nested != null) {
          final subNested = nested[subKey];
          if (subNested != null) value = subNested['id'];
        }
      } else {
        final nested = item[key];
        if (nested != null) value = nested['id'];
      }
      if (value != null) ids.add(value);
    }
    return ids.length;
  }

  Future<void> _onExportReport(
    ExportSchoolReportRequested event,
    Emitter<SchoolReportState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SchoolReportLoaded) {
      emit(SchoolReportError('Aucune donnée chargée à exporter'));
      return;
    }

    emit(SchoolReportExporting(
      event.format,
      attendanceData: currentState.attendanceData,
      gradesData: currentState.gradesData,
      summaryStats: currentState.summaryStats,
    ));

    try {
      if (event.data.isEmpty) {
        emit(SchoolReportExportError(
          'Aucune donnée à exporter',
          attendanceData: currentState.attendanceData,
          gradesData: currentState.gradesData,
          summaryStats: currentState.summaryStats,
        ));
        return;
      }

      String filePath;

      switch (event.format) {
        case 'excel':
          filePath = await _exportToCSV(event.data, event.reportType);
          break;
        case 'pdf':
        case 'word':
          filePath = await _exportToHTML(event.data, event.reportType);
          break;
        default:
          throw Exception('Format non supporté: ${event.format}');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Fichier non créé');
      }

      print('✅ Export réussi: $filePath');

      emit(SchoolReportExportSuccess(
        filePath,
        attendanceData: currentState.attendanceData,
        gradesData: currentState.gradesData,
        summaryStats: currentState.summaryStats,
      ));
    } catch (e, stackTrace) {
      print('❌ Erreur export: $e');
      print(stackTrace);
      emit(SchoolReportExportError(
        'Erreur export: $e',
        attendanceData: currentState.attendanceData,
        gradesData: currentState.gradesData,
        summaryStats: currentState.summaryStats,
      ));
    }
  }

  Future<String> _exportToCSV(
    List<Map<String, dynamic>> data,
    String reportType,
  ) async {
    try {
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
      final fileName = 'EduConnect_${reportType}_${now.day}${now.month}_${now.hour}${now.minute}.csv';

      final publicFilePath = publicPath != null ? '$publicPath/$fileName' : null;
      final localFilePath = '$localPath/$fileName';

      List<String> headers;
      if (reportType == 'attendance') {
        headers = ['Date', 'Cours', 'Horaire', 'Classe', 'Eleve', 'Enseignant', 'Statut'];
      } else {
        headers = ['Date', 'Classe', 'Eleve', 'Matiere', 'Coefficient', 'Note'];
      }

      final csv = StringBuffer();
      csv.writeln(headers.join(';'));

      for (final row in data) {
        List<String> values;
        if (reportType == 'attendance') {
          final dateStr = row['date'] as String?;
          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
          final schedule = row['schedules'] as Map<String, dynamic>?;
          final student = row['students'] as Map<String, dynamic>?;
          final teacher = row['teachers'] as Map<String, dynamic>?;

          values = [
            date != null ? '${date.day}/${date.month}/${date.year}' : '-',
            schedule?['subjects']?['name']?.toString() ?? '-',
            '${schedule?['start_time']?.toString() ?? '--:--'}-${schedule?['end_time']?.toString() ?? '--:--'}',
            '${schedule?['classes']?['level']?.toString() ?? ''} ${schedule?['classes']?['name']?.toString() ?? ''}'.trim(),
            '${student?['last_name']?.toString() ?? ''} ${student?['first_name']?.toString() ?? ''}'.trim(),
            '${teacher?['last_name']?.toString() ?? ''} ${teacher?['first_name']?.toString() ?? ''}'.trim(),
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

          values = [
            date != null ? '${date.day}/${date.month}/${date.year}' : '-',
            '${classe?['level']?.toString() ?? ''} ${classe?['name']?.toString() ?? ''}'.trim(),
            '${student?['last_name']?.toString() ?? ''} ${student?['first_name']?.toString() ?? ''}'.trim(),
            row['subjects']?['name']?.toString() ?? '-',
            coefficient.toString(),
            '${noteSur20.toStringAsFixed(2)}/20',
          ];
        }

        final escapedValues = values.map((v) {
          if (v.contains(';') || v.contains('"')) {
            return '"${v.replaceAll('"', '""')}"';
          }
          return v;
        }).toList();

        csv.writeln(escapedValues.join(';'));
      }

      if (publicFilePath != null) {
        final publicFile = File(publicFilePath);
        await publicFile.writeAsString(csv.toString(), encoding: utf8);
        print('✅ CSV public: $publicFilePath');
      }

      final localFile = File(localFilePath);
      await localFile.writeAsString(csv.toString(), encoding: utf8);
      print('✅ CSV local: $localFilePath');

      return publicFilePath ?? localFilePath;
    } catch (e, stackTrace) {
      print('❌ Erreur création CSV: $e');
      print(stackTrace);
      throw Exception('Impossible de créer le fichier CSV: $e');
    }
  }

  Future<String> _exportToHTML(
    List<Map<String, dynamic>> data,
    String reportType,
  ) async {
    try {
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
      final fileName = 'EduConnect_${reportType}_${now.day}${now.month}_${now.hour}${now.minute}.html';

      final publicFilePath = publicPath != null ? '$publicPath/$fileName' : null;
      final localFilePath = '$localPath/$fileName';

      final title = reportType == 'attendance' ? "Rapport d'Assiduité" : "Rapport de Notes";

      final html = StringBuffer();
      html.writeln('<!DOCTYPE html>');
      html.writeln('<html><head><meta charset="UTF-8">');
      html.writeln('<title>$title</title>');
      html.writeln('''
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
</style>
</head>
<body>
<h1>$title</h1>
<p class="meta">Généré le ${now.day}/${now.month}/${now.year} • ${data.length} enregistrements</p>
<table>
<thead>
<tr>
''');

      if (reportType == 'attendance') {
        html.writeln(
            '<th>Date</th><th>Cours</th><th>Horaire</th><th>Classe</th><th>Élève</th><th>Enseignant</th><th>Statut</th></tr></thead><tbody>');

        for (final row in data) {
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
              ? 'Présent'
              : status == 'absent'
                  ? 'Absent'
                  : status == 'late'
                      ? 'Retard'
                      : '-';

          html.writeln('''
<tr>
<td>${date != null ? '${date.day}/${date.month}/${date.year}' : '-'}</td>
<td>${schedule?['subjects']?['name']?.toString() ?? '-'}</td>
<td>${schedule?['start_time']?.toString() ?? '--:--'}-${schedule?['end_time']?.toString() ?? '--:--'}</td>
<td>${schedule?['classes']?['level']?.toString() ?? ''} ${schedule?['classes']?['name']?.toString() ?? ''}</td>
<td>${student?['last_name']?.toString() ?? ''} ${student?['first_name']?.toString() ?? ''}</td>
<td>${teacher?['last_name']?.toString() ?? ''} ${teacher?['first_name']?.toString() ?? ''}</td>
<td class="$statusClass">$statusLabel</td>
</tr>''');
        }
      } else {
        html.writeln(
            '<th>Date</th><th>Classe</th><th>Élève</th><th>Matière</th><th>Coef</th><th>Note</th></tr></thead><tbody>');

        for (final row in data) {
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

          html.writeln('''
<tr>
<td>${date != null ? '${date.day}/${date.month}/${date.year}' : '-'}</td>
<td>${classe?['level']?.toString() ?? ''} ${classe?['name']?.toString() ?? ''}</td>
<td>${student?['last_name']?.toString() ?? ''} ${student?['first_name']?.toString() ?? ''}</td>
<td>${row['subjects']?['name']?.toString() ?? '-'}</td>
<td>${row['coefficient'] ?? 1}</td>
<td class="$noteClass">${noteSur20.toStringAsFixed(1)}/20</td>
</tr>''');
        }
      }

      html.writeln('''
</tbody>
</table>
</body>
</html>''');

      if (publicFilePath != null) {
        final publicFile = File(publicFilePath);
        await publicFile.writeAsString(html.toString(), encoding: utf8);
        print('✅ HTML public: $publicFilePath');
      }

      final localFile = File(localFilePath);
      await localFile.writeAsString(html.toString(), encoding: utf8);
      print('✅ HTML local: $localFilePath');

      return publicFilePath ?? localFilePath;
    } catch (e, stackTrace) {
      print('❌ Erreur création HTML: $e');
      print(stackTrace);
      throw Exception('Impossible de créer le fichier HTML: $e');
    }
  }
}