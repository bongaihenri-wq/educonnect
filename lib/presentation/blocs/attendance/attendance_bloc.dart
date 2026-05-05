// lib/presentation/blocs/attendance/attendance_bloc.dart
import 'package:educonnect/data/models/attendance_model.dart';
import 'package:educonnect/services/teacher_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:educonnect/data/models/class_model.dart';
import 'package:educonnect/data/models/course_model.dart';
import 'package:educonnect/data/models/teacher_class_schedule_model.dart';
import 'package:educonnect/data/repositories/attendance_repository.dart';
import 'package:educonnect/data/repositories/class_repository.dart';
import 'package:educonnect/data/repositories/student_repository.dart';
import 'package:educonnect/data/repositories/course_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _attendanceRepository;
  final ClassRepository _classRepository;
  final StudentRepository _studentRepository;
  final CourseRepository _courseRepository;
  final TeacherService _teacherService;

  AttendanceBloc({
    required AttendanceRepository attendanceRepository,
    required ClassRepository classRepository,
    required StudentRepository studentRepository,
    required CourseRepository courseRepository,
    required TeacherService teacherService,
  })  : _attendanceRepository = attendanceRepository,
        _classRepository = classRepository,
        _studentRepository = studentRepository,
        _courseRepository = courseRepository,
        _teacherService = teacherService,
        super(AttendanceState(selectedDate: DateTime.now(), teacherSchedule: [])) {
    
    on<AttendanceLoadClassesRequested>(_onLoadClasses);
    on<AttendanceClassSelected>(_onClassSelected);
    on<AttendanceLoadStudentsRequested>(_onLoadStudents);
    on<AttendanceDetectCurrentCourse>(_onDetectCurrentCourse);
    on<AttendanceCourseChanged>(_onCourseChanged);
    on<AttendanceStudentStatusUpdated>(_onStudentStatusUpdated);
    on<AttendanceMarkAllPresent>(_onMarkAllPresent);
    on<AttendanceMarkAllAbsent>(_onMarkAllAbsent);
    on<AttendanceToggleStatus>(_onToggleStatus);
    on<AttendanceSubmitRequested>(_onSubmit);
    on<AttendanceDateChanged>(_onDateChanged);
    on<AttendanceReplaceConfirmed>(_onReplaceConfirmed);
  }

  // ✅ _onLoadClasses - INCHANGÉ
  Future<void> _onLoadClasses(
    AttendanceLoadClassesRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, schoolId: event.schoolId));
    
    try {
      if (event.teacherId.isEmpty || event.schoolId.isEmpty) {
        emit(state.copyWith(isLoading: false, teacherSchedule: []));
        return;
      }
      
      final response = await _teacherService.getTeacherSchedule(
        teacherId: event.teacherId,
        schoolId: event.schoolId,
      );
      
      final schedules = response.map((json) => TeacherClassScheduleModel.fromJson(json)).toList();
      
      emit(state.copyWith(
        teacherSchedule: schedules,
        isLoading: false,
      ));
    } catch (e) {
      if (e.toString().contains('empty') || e.toString().contains('null')) {
        emit(state.copyWith(isLoading: false, teacherSchedule: []));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Erreur: ${e.toString()}',
        ));
      }
    }
  }

  // ✅ _onClassSelected - INCHANGÉ
  Future<void> _onClassSelected(
    AttendanceClassSelected event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(
      selectedClass: event.selectedClass,
      schoolId: event.schoolId,
      currentCourse: event.currentCourse,
      clearCurrentCourse: false,
      attendanceRecords: {},
      startTime: DateTime.now(),
      completionTime: null,
      isSuccess: false,
    ));

    add(AttendanceLoadStudentsRequested(
      classId: event.selectedClass.id,
      schoolId: event.schoolId,
    ));
    
    if (event.currentCourse == null) {
      add(AttendanceDetectCurrentCourse(
        classId: event.selectedClass.id,
        dateTime: state.selectedDate,
        schoolId: event.schoolId,
      ));
    }
  }

  // ✅ _onLoadStudents - INCHANGÉ
  Future<void> _onLoadStudents(
    AttendanceLoadStudentsRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final students = await _studentRepository.getStudentsByClass(event.classId);
      
      final Map<String, AttendanceStatus> defaultRecords = {
        for (var student in students) student.id: AttendanceStatus.present
      };
      
      emit(state.copyWith(
        isLoading: false,
        students: students,
        attendanceRecords: defaultRecords,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des élèves',
      ));
    }
  }

  // ✅ _onDetectCurrentCourse - INCHANGÉ
  Future<void> _onDetectCurrentCourse(
    AttendanceDetectCurrentCourse event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final courses = await _courseRepository.getCoursesByClass(event.classId);
      final now = event.dateTime;
      
      final todayCourses = courses.where((c) => c.dayOfWeek == now.weekday).toList();
      CourseModel? currentCourse;

      if (todayCourses.isNotEmpty) {
        try {
          currentCourse = todayCourses.firstWhere((c) => c.isOngoing);
        } catch (_) {
          todayCourses.sort((a, b) => a.startTime.compareTo(b.startTime));
          final currentTimeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
          
          try {
            currentCourse = todayCourses.firstWhere((c) => c.startTime.compareTo(currentTimeStr) >= 0);
          } catch (_) {
            currentCourse = todayCourses.first;
          }
        }
      }

      emit(state.copyWith(
        currentCourse: currentCourse,
        availableCourses: todayCourses,
      ));
    } catch (e) {
      emit(state.copyWith(availableCourses: []));
    }
  }

  void _onCourseChanged(AttendanceCourseChanged event, Emitter<AttendanceState> emit) {
    emit(state.copyWith(currentCourse: event.course));
  }

  void _onToggleStatus(AttendanceToggleStatus event, Emitter<AttendanceState> emit) {
    final currentStatus = state.attendanceRecords[event.studentId] ?? AttendanceStatus.present;
    AttendanceStatus newStatus;

    if (currentStatus == AttendanceStatus.present) newStatus = AttendanceStatus.absent;
    else if (currentStatus == AttendanceStatus.absent) newStatus = AttendanceStatus.late;
    else newStatus = AttendanceStatus.present;

    final newRecords = Map<String, AttendanceStatus>.from(state.attendanceRecords)..[event.studentId] = newStatus;
    emit(state.copyWith(attendanceRecords: newRecords));
  }

  void _onStudentStatusUpdated(AttendanceStudentStatusUpdated event, Emitter<AttendanceState> emit) {
    final newRecords = Map<String, AttendanceStatus>.from(state.attendanceRecords)..[event.studentId] = event.status;
    emit(state.copyWith(attendanceRecords: newRecords));
  }

  void _onMarkAllPresent(AttendanceMarkAllPresent event, Emitter<AttendanceState> emit) {
    final newRecords = { for (var s in state.students) s.id : AttendanceStatus.present };
    emit(state.copyWith(attendanceRecords: newRecords));
  }

  void _onMarkAllAbsent(AttendanceMarkAllAbsent event, Emitter<AttendanceState> emit) {
    final newRecords = { for (var s in state.students) s.id : AttendanceStatus.absent };
    emit(state.copyWith(attendanceRecords: newRecords));
  }

  // ✅ _onSubmit - CORRIGÉ : fermeture des accolades manquantes
  Future<void> _onSubmit(AttendanceSubmitRequested event, Emitter<AttendanceState> emit) async {
    if (state.currentCourse == null) {
      emit(state.copyWith(error: 'Veuillez sélectionner un cours'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true, clearWarning: true));

    try {
      // ✅ Vérifier si appel déjà existant
      final existing = await _attendanceRepository.checkExistingAttendance(
        classId: state.selectedClass!.id,
        courseId: state.currentCourse!.id,
        date: event.date,
        teacherId: event.teacherId,
        schoolId: event.schoolId,
      );

      if (existing) {
        // ✅ Avertir mais ne pas sauvegarder encore
        emit(state.copyWith(
          isSubmitting: false,
          showReplaceDialog: true,
          warning: 'Un appel existe déjà pour ce cours. Voulez-vous le remplacer ?',
        ));
        return;
      }

      // ✅ Pas d'existant, sauvegarder directement
      await _performSave(event.date, event.teacherId, event.schoolId, emit);
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: 'Erreur lors de la vérification'));
    }
  }

  // ✅ _onReplaceConfirmed - CORRIGÉ : accolades fermées correctement
  Future<void> _onReplaceConfirmed(
    AttendanceReplaceConfirmed event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      showReplaceDialog: false,
      clearWarning: true,
    ));

    await _performSave(event.date, event.teacherId, event.schoolId, emit);
  }

  // ✅ _performSave - CORRIGÉ : accolades fermées correctement
  Future<void> _performSave(
    DateTime date,
    String teacherId,
    String schoolId,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      await _attendanceRepository.saveAttendance(
        classId: state.selectedClass!.id,
        courseId: state.currentCourse!.id,
        date: date,
        records: state.attendanceRecords,
        schoolId: schoolId,
        teacherId: teacherId,
      );

      await _notifyParents(state.attendanceRecords);

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        completionTime: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        error: 'Erreur lors de la sauvegarde: ${e.toString()}',
      ));
    }
  }

  // ✅ _notifyParents - AJOUTÉ (manquait dans ton code)
  Future<void> _notifyParents(Map<String, AttendanceStatus> records) async {
    final absentsAndLates = records.entries
        .where((e) => e.value == AttendanceStatus.absent || e.value == AttendanceStatus.late)
        .map((e) => e.key)
        .toList();

    if (absentsAndLates.isEmpty) return;

    try {
      await _attendanceRepository.notifyParents(
        studentIds: absentsAndLates,
        date: state.selectedDate,
        className: state.selectedClass?.name,
        courseName: state.currentCourse?.name,
        schoolId: state.schoolId,
      );
    } catch (e) {
      debugPrint('Notification failure: $e');
    }
  }

  // ✅ _onDateChanged - INCHANGÉ
  void _onDateChanged(AttendanceDateChanged event, Emitter<AttendanceState> emit) {
    emit(state.copyWith(
      selectedDate: event.newDate,
      attendanceRecords: {},
      clearCurrentCourse: true,
      startTime: null,
      completionTime: null,
      isSuccess: false,
    ));

    if (state.selectedClass != null) {
      add(AttendanceDetectCurrentCourse(
        classId: state.selectedClass!.id,
        dateTime: event.newDate,
        schoolId: state.schoolId,
      ));
    }
  }
}