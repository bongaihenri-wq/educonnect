import 'package:equatable/equatable.dart';

class ClassModel extends Equatable {
  final String id;
  final String name;
  final String levelId;
  final String schoolId;
  final String? levelName;
  final String? mainTeacherId;
  final String? mainTeacherName;
  final int? capacity;
  final int? studentCount;
  final DateTime? createdAt;

  const ClassModel({
    required this.id,
    required this.name,
    required this.levelId,
    required this.schoolId,
    this.levelName,
    this.mainTeacherId,
    this.mainTeacherName,
    this.capacity,
    this.studentCount,
    this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'] ?? '',
      levelId: json['level_id'] ?? '',
      schoolId: json['school_id'] ?? '',
      levelName: json['levels']?['name'],
      mainTeacherId: json['main_teacher_id'],
      mainTeacherName: json['teachers'] != null
          ? '${json['teachers']['first_name']} ${json['teachers']['last_name']}'
          : null,
      capacity: json['capacity'],
      studentCount: json['student_count'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level_id': levelId,
      'school_id': schoolId,
      'main_teacher_id': mainTeacherId,
      'capacity': capacity,
      'student_count': studentCount,
    };
  }

  String get displayName => levelName != null ? '$levelName $name' : name;

  @override
  List<Object?> get props => [
        id,
        name,
        levelId,
        schoolId,
        levelName,
        mainTeacherId,
        mainTeacherName,
        capacity,
        studentCount,
        createdAt,
      ];
}
