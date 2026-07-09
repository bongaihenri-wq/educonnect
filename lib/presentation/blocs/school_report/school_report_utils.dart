// lib/presentation/blocs/school_report/school_report_utils.dart

int parseCount(dynamic rawValue) {
  if (rawValue == null) return 0;
  if (rawValue is int) return rawValue;
  if (rawValue is double) return rawValue.toInt();
  if (rawValue is num) return rawValue.toInt();
  if (rawValue is String) {
    final cleaned = rawValue.trim().replaceAll('"', '').replaceAll("'", '');
    return int.tryParse(cleaned) ?? 0;
  }
  return int.tryParse(rawValue.toString().trim()) ?? 0;
}

Map<String, dynamic> calculateSummary(
  List<Map<String, dynamic>> attendance,
  List<Map<String, dynamic>> grades,
) {
  int totalPresent = 0;
  int totalAbsent = 0;
  int totalLate = 0;
  double totalGrade = 0;
  int gradeCount = 0;

  for (final a in attendance) {
    final status = a['status'] as String?;
    if (status == 'present') totalPresent++;
    if (status == 'absent') totalAbsent++;
    if (status == 'late') totalLate++;
  }

  for (final g in grades) {
    final score = (g['score'] as num?)?.toDouble() ?? 0;
    final maxScore = (g['max_score'] as num?)?.toDouble() ?? 20;
    final noteSur20 = maxScore > 0 ? (score / maxScore) * 20 : 0;
    totalGrade += noteSur20;
    gradeCount++;
  }

  final totalAttendance = attendance.length;
  final presenceRate = totalAttendance > 0
      ? (totalPresent / totalAttendance * 100).toStringAsFixed(1)
      : '0';

  return {
    'total_students': _extractUniqueCount(attendance, 'students'),
    'total_classes': _extractUniqueCount(attendance, 'schedules', 'classes'),
    'total_teachers': _extractUniqueCount(attendance, 'teachers'),
    'total_present': totalPresent,
    'total_absent': totalAbsent,
    'total_late': totalLate,
    'presence_rate': presenceRate,
    'average_grade':
        gradeCount > 0 ? (totalGrade / gradeCount).toStringAsFixed(2) : '0',
    'total_grades': gradeCount,
  };
}

int _extractUniqueCount(
  List<Map<String, dynamic>> data,
  String key, [
  String? subKey,
]) {
  final ids = <dynamic>{};
  for (final item in data) {
    dynamic value;
    if (subKey != null) {
      final nested = item[key];
      if (nested != null) {
        final subNested = nested[subKey];
        if (subNested != null) value = subNested['id'];
      }
    } else {
      final nested = item[key];
      if (nested != null) value = nested['id'];
    }
    if (value != null) ids.add(value);
  }
  return ids.length;
}
