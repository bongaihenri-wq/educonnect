import 'package:equatable/equatable.dart';

class StudentModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String matricule;
  final String classId;
  final String? className;
  final String? levelName;
  final DateTime? birthDate;
  final String? gender;
  final String? parentId;
  final String? parentName;
  final DateTime? createdAt;

  const StudentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.matricule,
    required this.classId,
    this.className,
    this.levelName,
    this.birthDate,
    this.gender,
    this.parentId,
    this.parentName,
    this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      matricule: json['matricule'] ?? '',
      classId: json['class_id'] ?? '',
      className: json['classes']?['name'],
      levelName: json['classes']?['levels']?['name'],
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date']) : null,
      gender: json['gender'],
      parentId: json['parent_id'],
      parentName: json['parent_profiles']?['users'] != null 
          ? '${json['parent_profiles']['users']['first_name']} ${json['parent_profiles']['users']['last_name']}'
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'matricule': matricule,
      'class_id': classId,
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'gender': gender,
      'parent_id': parentId,
    };
  }

  /// Nom complet de l eleve
  String get fullName => '$firstName $lastName';

  /// Initiales pour avatar
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        matricule,
        classId,
        className,
        levelName,
        birthDate,
        gender,
        parentId,
        parentName,
        createdAt,
      ];
}