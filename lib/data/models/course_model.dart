// lib/data/models/course_model.dart
import 'package:equatable/equatable.dart';

class CourseModel extends Equatable {
  final String id;
  final String name;              // Nom de la matière
  final String subjectId;
  final String classId;
  final String className;         // ✅ AJOUTÉ
  final String teacherId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String? subjectName;
  final String? teacherName;
  final String schoolId;
  final String? levelName;

  const CourseModel({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.classId,
    this.className = '',
    required this.teacherId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.subjectName,
    this.teacherName, required this.schoolId, this.levelName,
  });

  // ✅ GETTER pour compatibilité
  String get subject => name;

  String get displayTime => '$startTime - $endTime';

  bool get isOngoing {
    final now = DateTime.now();
    if (now.weekday != dayOfWeek) return false;
    final nowMinutes = now.hour * 60 + now.minute;
    final startParts = startTime.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endParts = endTime.split(':');
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

factory CourseModel.fromJson(Map<String, dynamic> json) {
  return CourseModel(
    id: json['id']?.toString() ?? '',
    name: json['subjects']?['name']?.toString() ?? json['name']?.toString() ?? 'Cours',
    subjectId: json['subject_id']?.toString() ?? '',
    classId: json['class_id']?.toString() ?? '',
    // ✅ CORRIGÉ : Vérifier plusieurs sources pour className
    className: json['classes']?['name']?.toString() 
        ?? json['class_name']?.toString() 
        ?? json['class']?['name']?.toString()
        ?? '',
    levelName: json['classes']?['level_name']?.toString() 
        ?? json['class']?['level_name']?.toString(),
    teacherId: json['teacher_id']?.toString() ?? '',
    // ✅ CORRIGÉ : day_of_week peut être int ou String
    dayOfWeek: json['day_of_week'] is int 
        ? json['day_of_week'] 
        : int.tryParse(json['day_of_week']?.toString() ?? '1') ?? 1,
    startTime: json['start_time']?.toString() ?? '00:00',
    endTime: json['end_time']?.toString() ?? '00:00',
    room: json['room']?.toString(),
    subjectName: json['subjects']?['name']?.toString(),
    teacherName: json['teachers'] != null 
        ? '${json['teachers']['first_name']} ${json['teachers']['last_name']}' 
        : null,
    schoolId: json['school_id']?.toString() ?? '',
  );
}

  CourseModel copyWith({
    String? id, String? name, String? subjectId, String? classId, String? className,
    String? teacherId, int? dayOfWeek, String? startTime, String? endTime,
    String? room, String? subjectName, String? teacherName, String? schoolId, String? levelName,
  }) {
    return CourseModel(
      id: id ?? this.id, name: name ?? this.name, subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId, className: className ?? this.className,
      teacherId: teacherId ?? this.teacherId, dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime, endTime: endTime ?? this.endTime,
      room: room ?? this.room, subjectName: subjectName ?? this.subjectName,
      teacherName: teacherName ?? this.teacherName, schoolId: schoolId ?? this.schoolId,
      levelName: levelName ?? this.levelName,
    );
  }

  @override
  List<Object?> get props => [id, name, subjectId, classId, className, teacherId, dayOfWeek, startTime, endTime, room, subjectName, teacherName, schoolId, levelName];
}