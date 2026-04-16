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

  AttendanceBloc({
    required AttendanceRepository attendanceRepository,
    required ClassRepository classRepository,
    required StudentRepository studentRepository,
    required CourseRepository courseRepository,
  })  : _attendanceRepository = attendanceRepository,
        _classRepository = classRepository,
        _studentRepository = studentRepository,
        _courseRepository = courseRepository,
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
  }

  // ========== CHARGEMENT CLASSES (Via Vue SQL) ==========
  
  Future<void> _onLoadClasses(
    AttendanceLoadClassesRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // Récupération du planning aplati par la vue SQL
      final List<TeacherClassScheduleModel> schedule = await _classRepository.getTeacherSchedule();
      
      // Transformation en ClassModel pour l'UI de sélection
      final allClassItems = schedule.map((s) => ClassModel(
        id: s.classId,
        name: s.className,
        levelId: '', 
        levelName: s.level,
        studentCount: s.studentCount,
      )).toList();

      // Suppression des doublons (si un prof a plusieurs matières dans la même classe)
      final uniqueClasses = { for (var c in allClassItems) c.id : c }.values.toList();

      emit(state.copyWith(
        isLoading: false,
        classes: uniqueClasses,
        teacherSchedule: schedule,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des classes: $e',
      ));
    }
  }

  // ========== SÉLECTION CLASSE + CHRONO ==========

  Future<void> _onClassSelected(
    AttendanceClassSelected event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(
      selectedClass: event.selectedClass,
      clearCurrentCourse: true,
      attendanceRecords: {},
      startTime: DateTime.now(), // Début du chrono
      completionTime: null, 
      isSuccess: false,
    ));

    add(AttendanceLoadStudentsRequested(event.selectedClass.id));
    add(AttendanceDetectCurrentCourse(
      classId: event.selectedClass.id,
      dateTime: state.selectedDate,
    ));
  }

  // ========== CHARGEMENT ÉLÈVES ==========

  Future<void> _onLoadStudents(
    AttendanceLoadStudentsRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final students = await _studentRepository.getStudentsByClass(event.classId);
      
      // Initialisation par défaut : tous présents
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

  // ========== DÉTECTION DU COURS ACTUEL ==========

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
        // 1. Cherche le cours qui se déroule actuellement
        try {
          currentCourse = todayCourses.firstWhere((c) => c.isOngoing);
        } catch (_) {
          // 2. Sinon, cherche le prochain cours de la journée
          todayCourses.sort((a, b) => a.startTime.compareTo(b.startTime));
          final currentTimeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
          
          try {
            currentCourse = todayCourses.firstWhere((c) => c.startTime.compareTo(currentTimeStr) >= 0);
          } catch (_) {
            currentCourse = todayCourses.first; // Par défaut, le premier
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

  // ========== GESTION DES STATUTS (UI) ==========

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

  // ========== SOUMISSION FINALE ==========

  Future<void> _onSubmit(AttendanceSubmitRequested event, Emitter<AttendanceState> emit) async {
    if (state.currentCourse == null) {
      emit(state.copyWith(error: 'Veuillez sélectionner un cours'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await _attendanceRepository.saveAttendance(
        classId: state.selectedClass!.id,
        courseId: state.currentCourse!.id,
        date: event.date,
        records: state.attendanceRecords,
      );

      // Notification automatique pour les parents
      await _notifyParents(state.attendanceRecords);

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        completionTime: DateTime.now(), // Arrêt du chrono
      ));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: 'Erreur lors de la sauvegarde'));
    }
  }

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
      );
    } catch (e) {
      debugPrint('Notification failure: $e');
    }
  }

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
      add(AttendanceDetectCurrentCourse(classId: state.selectedClass!.id, dateTime: event.newDate));
    }
  }
}
