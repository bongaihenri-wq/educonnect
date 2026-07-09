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
  final int? totalAttendanceCount;
  final int? totalGradesCount;

  const SchoolReportLoadingMore({
    required this.attendanceData,
    required this.gradesData,
    required this.summaryStats,
    this.isLoadingAttendance = false,
    this.isLoadingGrades = false,
    this.totalAttendanceCount,
    this.totalGradesCount,
  });

  @override
  List<Object?> get props => [
        attendanceData,
        gradesData,
        summaryStats,
        isLoadingAttendance,
        isLoadingGrades,
        totalAttendanceCount,
        totalGradesCount,
      ];
}

class SchoolReportLoaded extends SchoolReportState {
  final List<Map<String, dynamic>> attendanceData;
  final List<Map<String, dynamic>> gradesData;
  final Map<String, dynamic> summaryStats;
  final bool hasMoreAttendance;
  final bool hasMoreGrades;
  final int currentPage;
  final int? totalAttendanceCount;
  final int? totalGradesCount;

  const SchoolReportLoaded({
    required this.attendanceData,
    required this.gradesData,
    required this.summaryStats,
    this.hasMoreAttendance = false,
    this.hasMoreGrades = false,
    this.currentPage = 0,
    this.totalAttendanceCount,
    this.totalGradesCount,
  });

  @override
  List<Object?> get props => [
        attendanceData,
        gradesData,
        summaryStats,
        hasMoreAttendance,
        hasMoreGrades,
        currentPage,
        totalAttendanceCount,
        totalGradesCount,
      ];
}

class SchoolReportExporting extends SchoolReportState {
  final String format;
  final List<Map<String, dynamic>> attendanceData;
  final List<Map<String, dynamic>> gradesData;
  final Map<String, dynamic> summaryStats;
  final int? totalAttendanceCount;
  final int? totalGradesCount;

  const SchoolReportExporting(
    this.format, {
    required this.attendanceData,
    required this.gradesData,
    required this.summaryStats,
    this.totalAttendanceCount,
    this.totalGradesCount,
  });

  @override
  List<Object?> get props => [
        format,
        attendanceData,
        gradesData,
        summaryStats,
        totalAttendanceCount,
        totalGradesCount,
      ];
}

class SchoolReportExportSuccess extends SchoolReportState {
  final String filePath;
  final List<Map<String, dynamic>> attendanceData;
  final List<Map<String, dynamic>> gradesData;
  final Map<String, dynamic> summaryStats;
  final int? totalAttendanceCount;
  final int? totalGradesCount;

  const SchoolReportExportSuccess(
    this.filePath, {
    required this.attendanceData,
    required this.gradesData,
    required this.summaryStats,
    this.totalAttendanceCount,
    this.totalGradesCount,
  });

  @override
  List<Object?> get props => [
        filePath,
        attendanceData,
        gradesData,
        summaryStats,
        totalAttendanceCount,
        totalGradesCount,
      ];
}

class SchoolReportExportError extends SchoolReportState {
  final String message;
  final List<Map<String, dynamic>> attendanceData;
  final List<Map<String, dynamic>> gradesData;
  final Map<String, dynamic> summaryStats;
  final int? totalAttendanceCount;
  final int? totalGradesCount;

  const SchoolReportExportError(
    this.message, {
    required this.attendanceData,
    required this.gradesData,
    required this.summaryStats,
    this.totalAttendanceCount,
    this.totalGradesCount,
  });

  @override
  List<Object?> get props => [
        message,
        attendanceData,
        gradesData,
        summaryStats,
        totalAttendanceCount,
        totalGradesCount,
      ];
}

class SchoolReportError extends SchoolReportState {
  final String message;

  const SchoolReportError(this.message);

  @override
  List<Object?> get props => [message];
}
