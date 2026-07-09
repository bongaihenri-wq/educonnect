// lib/presentation/blocs/school_report/school_report_bloc.dart
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'school_report_event.dart';
import 'school_report_state.dart';
import 'school_report_data_loader.dart';
import 'school_report_counter.dart';
import 'school_report_exporter.dart';
import 'school_report_utils.dart';

class SchoolReportBloc extends Bloc<SchoolReportEvent, SchoolReportState> {
  final _dataLoader = SchoolReportDataLoader();
  final _counter = SchoolReportCounter();
  final _exporter = SchoolReportExporter();
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
      final attendanceData = await _dataLoader.loadAttendance(
        schoolId: event.schoolId,
        periodId: event.periodId,
        startDate: event.startDate,
        endDate: event.endDate,
        classId: event.classId,
        studentId: event.studentId,
        subjectId: event.subjectId,
        teacherId: event.teacherId,
        page: 0,
      );

      final gradesData = await _dataLoader.loadGrades(
        schoolId: event.schoolId,
        periodId: event.periodId,
        startDate: event.startDate,
        endDate: event.endDate,
        classId: event.classId,
        studentId: event.studentId,
        subjectId: event.subjectId,
        teacherId: event.teacherId,
        page: 0,
      );

      final totalAttendanceCount = await _counter.countAttendance(
        schoolId: event.schoolId,
        periodId: event.periodId,
        startDate: event.startDate,
        endDate: event.endDate,
        classId: event.classId,
        studentId: event.studentId,
        subjectId: event.subjectId,
        teacherId: event.teacherId,
      );

      final totalGradesCount = await _counter.countGrades(
        schoolId: event.schoolId,
        periodId: event.periodId,
        startDate: event.startDate,
        endDate: event.endDate,
        classId: event.classId,
        studentId: event.studentId,
        subjectId: event.subjectId,
        teacherId: event.teacherId,
      );

      print(
          '📊 TOTALS → attendance: $totalAttendanceCount, grades: $totalGradesCount');

      final summaryStats = calculateSummary(attendanceData, gradesData);

      emit(SchoolReportLoaded(
        attendanceData: attendanceData,
        gradesData: gradesData,
        summaryStats: summaryStats,
        hasMoreAttendance: attendanceData.length >= _pageSize,
        hasMoreGrades: gradesData.length >= _pageSize,
        currentPage: 0,
        totalAttendanceCount: totalAttendanceCount,
        totalGradesCount: totalGradesCount,
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
      totalAttendanceCount: currentState.totalAttendanceCount,
      totalGradesCount: currentState.totalGradesCount,
    ));

    try {
      final nextPage = currentState.currentPage + 1;
      List<Map<String, dynamic>> newAttendance = [];
      List<Map<String, dynamic>> newGrades = [];

      if (event.reportType == 'attendance') {
        newAttendance = await _dataLoader.loadAttendance(
          schoolId: event.schoolId,
          periodId: event.periodId,
          startDate: event.startDate,
          endDate: event.endDate,
          classId: event.classId,
          studentId: event.studentId,
          subjectId: event.subjectId,
          teacherId: event.teacherId,
          page: nextPage,
        );
      } else {
        newGrades = await _dataLoader.loadGrades(
          schoolId: event.schoolId,
          periodId: event.periodId,
          startDate: event.startDate,
          endDate: event.endDate,
          classId: event.classId,
          studentId: event.studentId,
          subjectId: event.subjectId,
          teacherId: event.teacherId,
          page: nextPage,
        );
      }

      final allAttendance = [...currentState.attendanceData, ...newAttendance];
      final allGrades = [...currentState.gradesData, ...newGrades];
      final summaryStats = calculateSummary(allAttendance, allGrades);

      emit(SchoolReportLoaded(
        attendanceData: allAttendance,
        gradesData: allGrades,
        summaryStats: summaryStats,
        hasMoreAttendance: newAttendance.length >= _pageSize,
        hasMoreGrades: newGrades.length >= _pageSize,
        currentPage: nextPage,
        totalAttendanceCount: currentState.totalAttendanceCount,
        totalGradesCount: currentState.totalGradesCount,
      ));
    } catch (e, stackTrace) {
      print('❌ Erreur load more: $e');
      print(stackTrace);
      emit(SchoolReportError('Erreur chargement: $e'));
    }
  }

  Future<void> _onExportReport(
    ExportSchoolReportRequested event,
    Emitter<SchoolReportState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SchoolReportLoaded) {
      emit(SchoolReportError('Aucune donnee chargee a exporter'));
      return;
    }

    emit(SchoolReportExporting(
      event.format,
      attendanceData: currentState.attendanceData,
      gradesData: currentState.gradesData,
      summaryStats: currentState.summaryStats,
      totalAttendanceCount: currentState.totalAttendanceCount,
      totalGradesCount: currentState.totalGradesCount,
    ));

    try {
      if (event.data.isEmpty) {
        emit(SchoolReportExportError(
          'Aucune donnee a exporter',
          attendanceData: currentState.attendanceData,
          gradesData: currentState.gradesData,
          summaryStats: currentState.summaryStats,
          totalAttendanceCount: currentState.totalAttendanceCount,
          totalGradesCount: currentState.totalGradesCount,
        ));
        return;
      }

      String filePath;
      switch (event.format) {
        case 'excel':
          filePath = await _exporter.exportToCSV(event.data, event.reportType);
          break;
        case 'pdf':
        case 'word':
          filePath = await _exporter.exportToHTML(event.data, event.reportType);
          break;
        default:
          throw Exception('Format non supporte: ${event.format}');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Fichier non cree');
      }

      print('✅ Export reussi: $filePath');

      emit(SchoolReportExportSuccess(
        filePath,
        attendanceData: currentState.attendanceData,
        gradesData: currentState.gradesData,
        summaryStats: currentState.summaryStats,
        totalAttendanceCount: currentState.totalAttendanceCount,
        totalGradesCount: currentState.totalGradesCount,
      ));
    } catch (e, stackTrace) {
      print('❌ Erreur export: $e');
      print(stackTrace);
      emit(SchoolReportExportError(
        'Erreur export: $e',
        attendanceData: currentState.attendanceData,
        gradesData: currentState.gradesData,
        summaryStats: currentState.summaryStats,
        totalAttendanceCount: currentState.totalAttendanceCount,
        totalGradesCount: currentState.totalGradesCount,
      ));
    }
  }
}
