// lib/presentation/blocs/school_report/school_report_state.dart
import 'package:equatable/equatable.dart';

abstract class SchoolReportState extends Equatable {
  const SchoolReportState();

  @override
  List<Object?> get props => [];
}

class SchoolReportInitial extends SchoolReportState {}

class SchoolReportLoading extends SchoolReportState {}

class SchoolReportLoadingMore extends SchoolReportState {
  final List<Map<String, dynamic>> attendanceData;
  final List<Map<String, dynamic>> gradesData;
  final Map<String, dynamic> summaryStats;
  final bool isLoadingAttendance;
  final bool isLoadingGrades;

  const SchoolReportLoadingMore({
    required this.attendanceData,
    required this.gradesData,
    required this.summaryStats,
    this.isLoadingAttendance = false,
    this.isLoadingGrades = false,
  });

  @override
  List<Object?> get props => [
        attendanceData,
        gradesData,
        summaryStats,
        isLoadingAttendance,
        isLoadingGrades,
      ];
}

class SchoolReportLoaded extends SchoolReportState {
  final List<Map<String, dynamic>> attendanceData;
  final List<Map<String, dynamic>> gradesData;
  final Map<String, dynamic> summaryStats;
  final bool hasMoreAttendance;
  final bool hasMoreGrades;
  final int currentPage;

  const SchoolReportLoaded({
    required this.attendanceData,
    required this.gradesData,
    required this.summaryStats,
    this.hasMoreAttendance = false,
    this.hasMoreGrades = false,
    this.currentPage = 0,
  });

  @override
  List<Object?> get props => [
        attendanceData,
        gradesData,
        summaryStats,
        hasMoreAttendance,
        hasMoreGrades,
        currentPage,
      ];
}

// ✅ CORRIGÉ : Conserve les données pendant l'export
class SchoolReportExporting extends SchoolReportState {
  final String format;
  final List<Map<String, dynamic>> attendanceData;
  final List<Map<String, dynamic>> gradesData;
  final Map<String, dynamic> summaryStats;

  const SchoolReportExporting(
    this.format, {
    required this.attendanceData,
    required this.gradesData,
    required this.summaryStats,
  });

  @override
  List<Object?> get props => [format, attendanceData, gradesData, summaryStats];
}

// ✅ CORRIGÉ : Conserve les données après export réussi
class SchoolReportExportSuccess extends SchoolReportState {
  final String filePath;
  final List<Map<String, dynamic>> attendanceData;
  final List<Map<String, dynamic>> gradesData;
  final Map<String, dynamic> summaryStats;

  const SchoolReportExportSuccess(
    this.filePath, {
    required this.attendanceData,
    required this.gradesData,
    required this.summaryStats,
  });

  @override
  List<Object?> get props => [filePath, attendanceData, gradesData, summaryStats];
}

// ✅ NOUVEAU : Erreur d'export avec conservation des données
class SchoolReportExportError extends SchoolReportState {
  final String message;
  final List<Map<String, dynamic>> attendanceData;
  final List<Map<String, dynamic>> gradesData;
  final Map<String, dynamic> summaryStats;

  const SchoolReportExportError(
    this.message, {
    required this.attendanceData,
    required this.gradesData,
    required this.summaryStats,
  });

  @override
  List<Object?> get props => [message, attendanceData, gradesData, summaryStats];
}

class SchoolReportError extends SchoolReportState {
  final String message;

  const SchoolReportError(this.message);

  @override
  List<Object?> get props => [message];
}