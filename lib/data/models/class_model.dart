import 'package:equatable/equatable.dart';

class ClassModel extends Equatable {
  final String id;
  final String name;
  final String levelId;
  final String? levelName;
  final String? mainTeacherId;
  final String? mainTeacherName;
  final int? capacity;
  final int? studentCount; // ⭐ AJOUTÉ
  final DateTime? createdAt;

  const ClassModel({
    required this.id,
    required this.name,
    required this.levelId,
    this.levelName,
    this.mainTeacherId,
    this.mainTeacherName,
    this.capacity,
    this.studentCount, // ⭐ AJOUTÉ
    this.createdAt,
    // ❌ SUPPRIMÉ : required String level,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'] ?? '',
      levelId: json['level_id'] ?? '',
      levelName: json['levels']?['name'],
      mainTeacherId: json['main_teacher_id'],
      mainTeacherName: json['teachers'] != null
          ? '${json['teachers']['first_name']} ${json['teachers']['last_name']}'
          : null,
      capacity: json['capacity'],
      studentCount: json['student_count'], // ⭐ AJOUTÉ
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
      'main_teacher_id': mainTeacherId,
      'capacity': capacity,
      'student_count': studentCount, // ⭐ AJOUTÉ
    };
  }

  String get displayName => levelName != null ? '$levelName $name' : name;

  @override
  List<Object?> get props => [
        id,
        name,
        levelId,
        levelName,
        mainTeacherId,
        mainTeacherName,
        capacity,
        studentCount, // ⭐ AJOUTÉ
        createdAt,
      ];
}
