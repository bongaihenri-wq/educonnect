// lib/presentation/blocs/report/report_state.dart
import 'package:equatable/equatable.dart';
import '../../../data/models/report_period_model.dart';
import '../../../data/repositories/report_repository.dart';

enum ReportViewMode { classView, studentView }

class ReportState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> classes;
  final List<ReportPeriodModel> availablePeriods;
  final ReportPeriodModel? selectedPeriod;
  final String? selectedClassId;
  final String? selectedClassName;
  final String? selectedStudentId;
  final String? selectedStudentName;
  final ReportViewMode viewMode;
  
  // ✅ NOUVEAU : Liste des élèves de la classe sélectionnée
  final List<Map<String, dynamic>> students;
  
  // Données
  final AttendanceStats? studentAttendance;
  final GradeStats? studentGrades;
  final ClassAttendanceStats? classAttendance;
  final ClassGradeStats? classGrades;
  final List<Map<String, dynamic>> comments;
  final bool isAddingComment;

  const ReportState({
    this.isLoading = false,
    this.error,
    this.classes = const [],
    this.availablePeriods = const [],
    this.selectedPeriod,
    this.selectedClassId,
    this.selectedClassName,
    this.selectedStudentId,
    this.selectedStudentName,
    this.viewMode = ReportViewMode.classView,
    this.students = const [],  // ✅
    this.studentAttendance,
    this.studentGrades,
    this.classAttendance,
    this.classGrades,
    this.comments = const [],
    this.isAddingComment = false,
  });

ReportState copyWith({
  bool? isLoading,
  String? error,
  List<Map<String, dynamic>>? classes,
  List<ReportPeriodModel>? availablePeriods,
  ReportPeriodModel? selectedPeriod,
  String? selectedClassId,
  String? selectedClassName,
  String? selectedStudentId,
  String? selectedStudentName,
  ReportViewMode? viewMode,
  List<Map<String, dynamic>>? students,
  AttendanceStats? studentAttendance,
  GradeStats? studentGrades,
  ClassAttendanceStats? classAttendance,
  ClassGradeStats? classGrades,
  List<Map<String, dynamic>>? comments,
  bool? isAddingComment,
  bool clearStudentData = false,
  bool clearError = false,
  bool clearClassData = false,
}) {
  return ReportState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    classes: classes ?? this.classes,
    availablePeriods: availablePeriods ?? this.availablePeriods,
    selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    selectedClassId: selectedClassId ?? this.selectedClassId,
    selectedClassName: selectedClassName ?? this.selectedClassName,
    selectedStudentId: clearStudentData ? null : selectedStudentId ?? this.selectedStudentId,
    selectedStudentName: clearStudentData ? null : selectedStudentName ?? this.selectedStudentName,
    viewMode: viewMode ?? this.viewMode,
    students: students ?? this.students,
    studentAttendance: clearStudentData ? null : studentAttendance ?? this.studentAttendance,
    studentGrades: clearStudentData ? null : studentGrades ?? this.studentGrades,
    classAttendance: clearStudentData ? null : classAttendance ?? this.classAttendance,
    classGrades: clearStudentData ? null : classGrades ?? this.classGrades,
    // ✅ CORRIGÉ : comments ne peut pas être null, utiliser const [] ou this.comments
    comments: clearStudentData ? const [] : comments ?? this.comments,
    isAddingComment: isAddingComment ?? this.isAddingComment,
  );
}

  @override
  List<Object?> get props => [
    isLoading, error, classes, availablePeriods, selectedPeriod,
    selectedClassId, selectedClassName, selectedStudentId, selectedStudentName,
    viewMode, students,  // ✅
    studentAttendance, studentGrades, classAttendance, classGrades,
    comments, isAddingComment,
  ];
}