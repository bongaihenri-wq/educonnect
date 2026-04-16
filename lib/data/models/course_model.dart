import 'package:equatable/equatable.dart';

class CourseModel extends Equatable {
  final String id;
  final String name;
  final String subjectId;
  final String classId;
  final String teacherId;
  final int dayOfWeek;
  final String startTime; // Format "HH:MM"
  final String endTime;   // Format "HH:MM"
  final String? room;
  final String? subjectName;
  final String? teacherName;

  const CourseModel({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.classId,
    required this.teacherId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.subjectName,
    this.teacherName,
  });

  // ⭐ AJOUTÉ : Pour l'affichage dans l'UI (ex: "08:00 - 10:00")
  String get displayTime => '$startTime - $endTime';

  // ⭐ AJOUTÉ : Pour la détection automatique du cours actuel
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
      id: json['id'] ?? '',
      name: json['name'] ?? json['subjects']?['name'] ?? 'Cours',
      subjectId: json['subject_id'] ?? '',
      classId: json['class_id'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 1,
      startTime: json['start_time'] ?? '00:00',
      endTime: json['end_time'] ?? '00:00',
      room: json['room'],
      subjectName: json['subjects']?['name'],
      teacherName: json['teachers'] != null
          ? '${json['teachers']['first_name']} ${json['teachers']['last_name']}'
          : null,
    );
  }

  // Méthode pour faciliter les tests ou les mises à jour
  CourseModel copyWith({
    String? id,
    String? name,
    String? subjectId,
    String? classId,
    String? teacherId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
    String? subjectName,
    String? teacherName,
  }) {
    return CourseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      subjectName: subjectName ?? this.subjectName,
      teacherName: teacherName ?? this.teacherName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        subjectId,
        classId,
        teacherId,
        dayOfWeek,
        startTime,
        endTime,
        room,
      ];
}