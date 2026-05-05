// lib/presentation/blocs/report/report_event.dart
import 'package:equatable/equatable.dart';
import '../../../data/models/report_period_model.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();
  @override
  List<Object?> get props => [];
}

class ReportLoadClassesRequested extends ReportEvent {
  final String teacherId;
  const ReportLoadClassesRequested(this.teacherId);
}

class ReportPeriodSelected extends ReportEvent {
  final ReportPeriodModel period;
  const ReportPeriodSelected(this.period);
}

class ReportClassSelected extends ReportEvent {
  final String classId;
  final String className;
  const ReportClassSelected(this.classId, this.className);
}

class ReportStudentSelected extends ReportEvent {
  final String? studentId;
  final String? studentName;  // ✅ AJOUTÉ
  const ReportStudentSelected({this.studentId, this.studentName});

  @override
  List<Object?> get props => [studentId, studentName];  // ✅
}

class ReportLoadDataRequested extends ReportEvent {
  const ReportLoadDataRequested();
}

class ReportAddCommentRequested extends ReportEvent {
  final String studentId;
  final String comment;
  const ReportAddCommentRequested(this.studentId, this.comment);
}