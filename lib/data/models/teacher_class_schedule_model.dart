import 'package:equatable/equatable.dart';

class TeacherClassScheduleModel extends Equatable {
  final String? scheduleId;      // ✅ AJOUTÉ : ID de l'emploi du temps (pour FK attendance)
  final String classId;
  final String className;
  final String level;
  final int studentCount;
  final String subjectId;
  final String subjectName;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String schoolId;

  const TeacherClassScheduleModel({
    this.scheduleId,             // ✅ AJOUTÉ
    required this.classId,
    required this.className,
    required this.level,
    required this.studentCount,
    required this.subjectId,
    required this.subjectName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    required this.schoolId,
  });

  factory TeacherClassScheduleModel.fromJson(Map<String, dynamic> json) {
    print('🔥🔥🔥 fromJson input: $json');
    // Cette logique supporte à la fois la Vue SQL (plate) et le .select() (imbriqué)
    return TeacherClassScheduleModel(
      scheduleId: json['id'] as String?,           // ✅ AJOUTÉ : schedule.id
      classId: json['class_id'] ?? '',
      className: json['class_name'] ?? json['classes']?['name'] ?? '',
      level: json['level'] ?? json['classes']?['level'] ?? '',  // ✅ CORRIGÉ : classes?['level'] direct
      studentCount: json['student_count'] ?? 0,
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject_name'] ?? json['subjects']?['name'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 1,
      startTime: json['start_time'] ?? '00:00',
      endTime: json['end_time'] ?? '00:00',
      room: json['room'],
      schoolId: json['school_id'] ?? '',
    );
  }

  // Indispensable pour ton Bloc
  TeacherClassScheduleModel copyWith({
    String? scheduleId,          // ✅ AJOUTÉ
    String? classId,
    String? className,
    String? level,
    int? studentCount,
    String? subjectId,
    String? subjectName,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
    String? schoolId,
  }) {
    return TeacherClassScheduleModel(
      scheduleId: scheduleId ?? this.scheduleId,   // ✅ AJOUTÉ
      classId: classId ?? this.classId,
      className: className ?? this.className,
      level: level ?? this.level,
      studentCount: studentCount ?? this.studentCount,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      schoolId: schoolId ?? this.schoolId,
    );
  }

  String get dayName {
    const days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return (dayOfWeek >= 1 && dayOfWeek <= 7) ? days[dayOfWeek] : '';
  }

  bool get isCurrentSlot {
    final now = DateTime.now();
    if (now.weekday != dayOfWeek) return false;
    final currentMin = now.hour * 60 + now.minute;
    final startMin = _toMin(startTime);
    final endMin = _toMin(endTime);
    return currentMin >= startMin && currentMin <= endMin;
  }

  int _toMin(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  @override
  List<Object?> get props => [scheduleId, classId, subjectId, dayOfWeek, startTime, endTime]; // ✅ AJOUTÉ scheduleId
}