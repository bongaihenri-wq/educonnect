import 'package:flutter/material.dart';

enum AttendanceStatus {
  present('Présent'),
  absent('Absent'),
  late('En retard');

  final String label;
  const AttendanceStatus(this.label);

  // Helper pour obtenir la couleur directement depuis l'enum (plus propre)
  Color get color {
    switch (this) {
      case AttendanceStatus.present: return const Color(0xFF14B8A6);
      case AttendanceStatus.absent: return const Color(0xFFFB7185);
      case AttendanceStatus.late: return const Color(0xFFF59E0B);
    }
  }
}

class CourseModel {
  final String id;
  final String name;      // Nom de la matière (ex: Mathématiques)
  final String className; // Nom de la classe (ex: Terminale S1)
  final String classId;   // ID technique pour récupérer les élèves
  final String startTime;
  final String endTime;

  CourseModel({
    required this.id,
    required this.name,
    required this.className,
    required this.classId,
    required this.startTime,
    required this.endTime,
  });

  // Factory pour transformer du JSON (API) en objet CourseModel
  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'],
      name: json['subject_name'],
      className: json['class_name'],
      classId: json['class_id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }
}

// Ajout d'un modèle pour les élèves (si tu ne l'as pas déjà)
class StudentModel {
  final String id;
  final String fullName;
  final String matricule;

  StudentModel({
    required this.id,
    required this.fullName,
    required this.matricule,
  });

  String get initials {
    if (fullName.isEmpty) return "?";
    List<String> names = fullName.split(" ");
    return names.length > 1 
        ? "${names[0][0]}${names[1][0]}".toUpperCase() 
        : names[0][0].toUpperCase();
  }
}