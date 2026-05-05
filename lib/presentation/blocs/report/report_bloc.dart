// lib/presentation/blocs/report/report_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/report_period_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/student_repository.dart';
import 'report_events.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _reportRepository;
  final ClassRepository _classRepository;
  final StudentRepository _studentRepository;
  final String _teacherId;
  final String _schoolId;

  ReportBloc({
    required ReportRepository reportRepository,
    required ClassRepository classRepository,
    required StudentRepository studentRepository,
    required String teacherId,
    required String schoolId,
  })  : _reportRepository = reportRepository,
        _classRepository = classRepository,
        _studentRepository = studentRepository,
        _teacherId = teacherId,
        _schoolId = schoolId,
        super(const ReportState()) {
    on<ReportLoadClassesRequested>(_onLoadClasses);
    on<ReportPeriodSelected>(_onPeriodSelected);
    on<ReportClassSelected>(_onClassSelected);
    on<ReportStudentSelected>(_onStudentSelected);
    on<ReportLoadDataRequested>(_onLoadData);
    on<ReportAddCommentRequested>(_onAddComment);
  }

  Future<void> _onLoadClasses(
    ReportLoadClassesRequested event,
    Emitter<ReportState> emit,
  ) async {
    final teacherId = event.teacherId.isNotEmpty ? event.teacherId : _teacherId;
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final classes = await _classRepository.getTeacherClasses(teacherId: teacherId);
      final classesMap = classes.map((c) => {
        'id': c.id,
        'name': c.name,
        'level_name': c.levelName ?? '',
        'capacity': c.capacity ?? 0,
      }).toList();

      final periods = ReportPeriodModel.generateForSchoolYear(
        schoolYear: '2025-2026',
        yearStart: DateTime(2025, 9, 1),
        yearEnd: DateTime(2026, 6, 30),
        trimesters: [
          {'number': 1, 'start_date': '2025-09-01', 'end_date': '2025-11-15'},
          {'number': 2, 'start_date': '2025-11-16', 'end_date': '2026-02-15'},
          {'number': 3, 'start_date': '2026-02-16', 'end_date': '2026-06-30'},
        ],
        semesters: null,
      );

      final currentPeriod = ReportPeriodModel.getCurrentPeriod(periods);

      emit(state.copyWith(
        isLoading: false,
        classes: classesMap,
        availablePeriods: periods,
        selectedPeriod: currentPeriod,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Erreur: $e'));
    }
  }

  Future<void> _onPeriodSelected(
    ReportPeriodSelected event,
    Emitter<ReportState> emit,
  ) async {
    emit(state.copyWith(selectedPeriod: event.period));
    if (state.selectedClassId != null) add(const ReportLoadDataRequested());
  }

 Future<void> _onClassSelected(
  ReportClassSelected event,
  Emitter<ReportState> emit,
) async {
  print('🔍 [8] _onClassSelected: ${event.classId}');

  emit(state.copyWith(
    selectedClassId: event.classId,
    selectedClassName: event.className,
    selectedStudentId: null,
    selectedStudentName: null,
    viewMode: ReportViewMode.classView,
    clearStudentData: true,
    clearClassData: false,
  ));

  try {
    print('🔍 [9] Loading students for class: ${event.classId}');
    final studentModels = await _studentRepository.getStudentsByClass(event.classId);
    print('🔍 [10] Students loaded: ${studentModels.length}');
    
    final students = studentModels.map((s) => {
      'id': s.id,
      'first_name': s.firstName,
      'last_name': s.lastName,
      'full_name': '${s.firstName} ${s.lastName}',
    }).toList();
    
    emit(state.copyWith(students: students));
    print('🔍 [11] Students emitted: ${students.length}');
  } catch (e) {
    print('🔍 [ERROR] Loading students: $e');
  }

  add(const ReportLoadDataRequested());
}

  Future<void> _onStudentSelected(
    ReportStudentSelected event,
    Emitter<ReportState> emit,
  ) async {
    emit(state.copyWith(
      selectedStudentId: event.studentId,
      selectedStudentName: event.studentName,
      viewMode: event.studentId != null ? ReportViewMode.studentView : ReportViewMode.classView,
      clearStudentData: false,
      clearClassData: event.studentId == null, // ✅ Effacer données élève si "Toute la classe"
    ));
    
    add(const ReportLoadDataRequested());
  }

  // ✅ CORRIGÉ : _onLoadData avec vérification isStudentView
  Future<void> _onLoadData(
    ReportLoadDataRequested event,
    Emitter<ReportState> emit,
  ) async {
    if (state.selectedPeriod == null || state.selectedClassId == null) return;
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // ✅ VÉRIFIER si on est en mode student ET qu'un élève est sélectionné
      final isStudentView = state.viewMode == ReportViewMode.studentView && state.selectedStudentId != null;
      
      if (isStudentView) {
        print('🔍 [LOAD] StudentView: ${state.selectedStudentId}');
        final attendance = await _reportRepository.getStudentAttendanceStats(
          studentId: state.selectedStudentId!,
          classId: state.selectedClassId!,
          teacherId: _teacherId,
          subject: 'all',
          period: state.selectedPeriod!,
        );
        print('🔍 [LOAD] Attendance days: ${attendance.dailyBreakdown.length}');
        final grades = await _reportRepository.getStudentGradeStats(
          studentId: state.selectedStudentId!,
          classId: state.selectedClassId!,
          teacherId: _teacherId,
          subject: 'all',
          period: state.selectedPeriod!,
        );
        print('🔍 [LOAD] Grades count: ${grades.grades.length}');
        
        emit(state.copyWith(
          isLoading: false,
          studentAttendance: attendance,
          studentGrades: grades,
          classAttendance: null, // ✅ Effacer données classe
          classGrades: null,
        ));
      } else {
        print('🔍 [LOAD] ClassView: ${state.selectedClassId}');
        final attendance = await _reportRepository.getClassAttendanceStats(
          classId: state.selectedClassId!,
          teacherId: _teacherId,
          subject: 'all',
          period: state.selectedPeriod!,
        );
        print('🔍 [LOAD] Top absents: ${attendance.topAbsentStudents.length}');
        final grades = await _reportRepository.getClassGradeStats(
          classId: state.selectedClassId!,
          teacherId: _teacherId,
          subject: 'all',
          period: state.selectedPeriod!,
        );
        print('🔍 [LOAD] Class average: ${grades.classAverage}');
        
        emit(state.copyWith(
          isLoading: false,
          classAttendance: attendance,
          classGrades: grades,
          studentAttendance: null, // ✅ Effacer données élève
          studentGrades: null,
        ));
      }
    } catch (e) {
      print('🔍 [LOAD ERROR] $e');
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAddComment(
    ReportAddCommentRequested event,
    Emitter<ReportState> emit,
  ) async {
    if (state.selectedPeriod == null || state.selectedClassId == null || state.selectedStudentId == null) return;
    emit(state.copyWith(isAddingComment: true));
    try {
      await _reportRepository.addComment(
        studentId: event.studentId,
        classId: state.selectedClassId!,
        schoolId: _schoolId,
        teacherId: _teacherId,
        subject: 'all',
        period: state.selectedPeriod!,
        comment: event.comment,
      );
      add(const ReportLoadDataRequested());
    } catch (e) {
      emit(state.copyWith(isAddingComment: false, error: 'Erreur ajout commentaire: ${e.toString()}'));
    }
  }
}