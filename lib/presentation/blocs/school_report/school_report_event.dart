// lib/presentation/blocs/school_report/school_report_event.dart
import 'package:equatable/equatable.dart';

abstract class SchoolReportEvent extends Equatable {
  const SchoolReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadSchoolReportRequested extends SchoolReportEvent {
  final String schoolId;
  final String? periodId;
  final String? startDate;
  final String? endDate;
  final String? classId;
  final String? studentId;
  final String? subjectId;
  final String? teacherId;

  const LoadSchoolReportRequested({
    required this.schoolId,
    this.periodId,
    this.startDate,
    this.endDate,
    this.classId,
    this.studentId,
    this.subjectId,
    this.teacherId,
  });

  @override
  List<Object?> get props => [
        schoolId,
        periodId,
        startDate,
        endDate,
        classId,
        studentId,
        subjectId,
        teacherId,
      ];
}

class LoadMoreReportRequested extends SchoolReportEvent {
  final String schoolId;
  final String? periodId;
  final String? startDate;
  final String? endDate;
  final String? classId;
  final String? studentId;
  final String? subjectId;
  final String? teacherId;
  final String reportType;

  const LoadMoreReportRequested({
    required this.schoolId,
    this.periodId,
    this.startDate,
    this.endDate,
    this.classId,
    this.studentId,
    this.subjectId,
    this.teacherId,
    required this.reportType,
  });

  @override
  List<Object?> get props => [
        schoolId,
        periodId,
        startDate,
        endDate,
        classId,
        studentId,
        subjectId,
        teacherId,
        reportType,
      ];
}

class ExportSchoolReportRequested extends SchoolReportEvent {
  final String format;
  final String reportType;
  final List<Map<String, dynamic>> data;

  const ExportSchoolReportRequested({
    required this.format,
    required this.reportType,
    required this.data,
  });

  @override
  List<Object?> get props => [format, reportType, data];
}