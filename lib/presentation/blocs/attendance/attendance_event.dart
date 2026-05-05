import 'package:equatable/equatable.dart';
import '/data/models/class_model.dart';
import '/data/models/course_model.dart';
import '/data/models/attendance_model.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class AttendanceLoadClassesRequested extends AttendanceEvent {
  final String teacherId;
  final String schoolId;

  const AttendanceLoadClassesRequested({
    required this.teacherId,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [teacherId, schoolId];
}

class AttendanceClassSelected extends AttendanceEvent {
  final ClassModel selectedClass;
  final String schoolId;
  final CourseModel? currentCourse; // ✅ AJOUTÉ

  const AttendanceClassSelected(
    this.selectedClass, {
    required this.schoolId,
    this.currentCourse, // ✅ AJOUTÉ
  });

  @override
  List<Object?> get props => [selectedClass, schoolId, currentCourse]; // ✅
}

class AttendanceLoadStudentsRequested extends AttendanceEvent {
  final String classId;
  final String schoolId;

  const AttendanceLoadStudentsRequested({
    required this.classId,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [classId, schoolId];
}

class AttendanceDetectCurrentCourse extends AttendanceEvent {
  final String classId;
  final DateTime dateTime;
  final String schoolId;

  const AttendanceDetectCurrentCourse({
    required this.classId,
    required this.dateTime,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [classId, dateTime, schoolId];
}

class AttendanceCourseChanged extends AttendanceEvent {
  final CourseModel? course;

  const AttendanceCourseChanged(this.course);

  @override
  List<Object?> get props => [course];
}

class AttendanceStudentStatusUpdated extends AttendanceEvent {
  final String studentId;
  final AttendanceStatus status;

  const AttendanceStudentStatusUpdated({
    required this.studentId,
    required this.status,
  });

  @override
  List<Object?> get props => [studentId, status];
}

class AttendanceToggleStatus extends AttendanceEvent {
  final String studentId;

  const AttendanceToggleStatus({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class AttendanceMarkAllPresent extends AttendanceEvent {
  const AttendanceMarkAllPresent();
}

class AttendanceMarkAllAbsent extends AttendanceEvent {
  const AttendanceMarkAllAbsent();
}

class AttendanceSubmitRequested extends AttendanceEvent {
  final DateTime date;
  final String teacherId;
  final String schoolId;

  const AttendanceSubmitRequested({
    required this.date,
    required this.teacherId,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [date, teacherId, schoolId];
}

class AttendanceDateChanged extends AttendanceEvent {
  final DateTime newDate;

  const AttendanceDateChanged(this.newDate);

  @override
  List<Object?> get props => [newDate];
}
class AttendanceReplaceConfirmed extends AttendanceEvent {
  final DateTime date;
  final String teacherId;
  final String schoolId;

  const AttendanceReplaceConfirmed({
    required this.date,
    required this.teacherId,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [date, teacherId, schoolId];
}