class ScheduleModel {
  final String id;
  final String subjectName;
  final String className;
  final String classId;
  final String teacherName; // Ajouté pour le récap admin
  final String room;
  final int dayOfWeek;      // Ajouté pour le filtrage par jour
  final String startTimeStr; // Format "HH:mm"
  final String endTimeStr;   // Format "HH:mm"

  ScheduleModel({
    required this.id,
    required this.subjectName,
    required this.className,
    required this.classId,
    required this.teacherName,
    required this.room,
    required this.dayOfWeek,
    required this.startTimeStr,
    required this.endTimeStr,
  });

  // Convertit l'heure String en DateTime pour la comparaison "isCurrent"
  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }
  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['schedule_id'].toString(),
      subjectName: map['subject_name'] ?? '',
      className: map['class_name'] ?? '',
      classId: map['class_id'].toString(),
      teacherName: map['teacher_full_name'] ?? '',
      room: map['room'] ?? 'N/A',
      dayOfWeek: map['day_of_week'] ?? 0,
      // On s'assure que les heures sont propres pour le parsing
      startTimeStr: map['start_time'].toString().substring(0, 5), // Garde "HH:mm"
      endTimeStr: map['end_time'].toString().substring(0, 5),
    );
  }

  bool get isCurrent {
    final now = DateTime.now();
    // On vérifie aussi que c'est le bon jour de la semaine (0=Dimanche, 1=Lundi...)
    if (now.weekday % 7 != dayOfWeek) return false; 
    
    final start = _parseTime(startTimeStr);
    final end = _parseTime(endTimeStr);
    return now.isAfter(start) && now.isBefore(end);
  }
}