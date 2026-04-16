class ScheduleModel {
  final String id;
  final String subjectName;
  final String className;
  final String classId;
  final DateTime startTime;
  final DateTime endTime;

  ScheduleModel({
    required this.id,
    required this.subjectName,
    required this.className,
    required this.classId,
    required this.startTime,
    required this.endTime,
  });

  // Vérifie si le cours est celui en cours actuellement
  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}