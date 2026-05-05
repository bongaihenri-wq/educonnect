import 'package:educonnect/data/models/attendance_model.dart';
import 'package:equatable/equatable.dart';
import '/data/models/student_model.dart';
import '/data/models/class_model.dart';
import '/data/models/course_model.dart';
import '/data/models/teacher_class_schedule_model.dart';

class AttendanceState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final List<ClassModel> classes;
  final ClassModel? selectedClass;
  final List<StudentModel> students;
  final Map<String, AttendanceStatus> attendanceRecords;
  final CourseModel? currentCourse;
  final List<CourseModel> availableCourses;
  final DateTime selectedDate;
  final bool isSuccess;
  final DateTime? startTime;
  final DateTime? completionTime;
  final List<TeacherClassScheduleModel> teacherSchedule;
  final String schoolId;
  final String teacherId;
  final bool showReplaceDialog;    // ✅ AJOUTÉ
  final String? warning;

  const AttendanceState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.classes = const [],
    this.selectedClass,
    this.students = const [],
    this.attendanceRecords = const {},
    this.currentCourse,
    this.availableCourses = const [],
    required this.selectedDate,
    this.isSuccess = false,
    this.startTime,
    this.completionTime,
    this.teacherSchedule = const [],
    this.schoolId = '',
    this.teacherId = '',
    this.showReplaceDialog = false, // ✅ AJOUTÉ
    this.warning,
  });

  AttendanceState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    List<ClassModel>? classes,
    ClassModel? selectedClass,
    List<StudentModel>? students,
    Map<String, AttendanceStatus>? attendanceRecords,
    CourseModel? currentCourse,
    List<CourseModel>? availableCourses,
    DateTime? selectedDate,
    bool? isSuccess,
    DateTime? startTime,
    DateTime? completionTime,
    List<TeacherClassScheduleModel>? teacherSchedule,
    String? schoolId,
    bool clearError = false,
    bool clearSelectedClass = false,
    bool clearCurrentCourse = false,
    bool? showReplaceDialog,
    String? warning, 
    bool clearWarning = false,

  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      classes: classes ?? this.classes,
      selectedClass: clearSelectedClass ? null : selectedClass ?? this.selectedClass,
      students: students ?? this.students,
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
      currentCourse: clearCurrentCourse ? null : currentCourse ?? this.currentCourse,
      availableCourses: availableCourses ?? this.availableCourses,
      selectedDate: selectedDate ?? this.selectedDate,
      isSuccess: isSuccess ?? this.isSuccess,
      startTime: startTime ?? this.startTime,
      completionTime: completionTime ?? this.completionTime,
      teacherSchedule: teacherSchedule ?? this.teacherSchedule,
      schoolId: schoolId ?? this.schoolId,
      showReplaceDialog: showReplaceDialog ?? this.showReplaceDialog,
      warning: clearWarning ? null : (warning ?? this.warning),


    );
  }

  int get presentCount => attendanceRecords.values.where((s) => s == AttendanceStatus.present).length;
  int get absentCount => attendanceRecords.values.where((s) => s == AttendanceStatus.absent).length;
  int get lateCount => attendanceRecords.values.where((s) => s == AttendanceStatus.late).length;
  int get remainingCount => students.length - attendanceRecords.length;
  bool get isComplete => students.isNotEmpty && attendanceRecords.length == students.length;
  double get completionPercentage => students.isEmpty ? 0 : (attendanceRecords.length / students.length) * 100;

  String get formattedDuration {
    if (startTime == null) return '--';
    final end = completionTime ?? DateTime.now();
    final duration = end.difference(startTime!);
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}min ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }

  bool get isQuickCompletion {
    if (startTime == null || completionTime == null) return false;
    final duration = completionTime!.difference(startTime!);
    return duration.inMinutes <= 5;
  }

  String? get quickCompletionMessage {
    if (!isSuccess || !isQuickCompletion) return null;
    return '🚀 Appel rapide ! ($formattedDuration)';
  }

  double get studentsPerMinute {
    if (startTime == null || students.isEmpty) return 0;
    final end = completionTime ?? DateTime.now();
    final minutes = end.difference(startTime!).inMinutes;
    if (minutes == 0) return students.length.toDouble();
    return students.length / minutes;
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        error,
        classes,
        selectedClass,
        students,
        attendanceRecords,
        currentCourse,
        availableCourses,
        selectedDate,
        isSuccess,
        startTime,
        completionTime,
        teacherSchedule,
        schoolId,
      ];
}
