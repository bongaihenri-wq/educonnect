import 'package:equatable/equatable.dart';
import '/../data/models/class_model.dart';
import '/../data/models/course_model.dart';


abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

// ========== CHARGEMENT INITIAL ==========

/// Récupérer les classes de l'enseignant connecté
class AttendanceLoadClassesRequested extends AttendanceEvent {
  const AttendanceLoadClassesRequested({required String classId, required String courseId});
}

// ========== SÉLECTION CLASSE ==========

/// Sélection d'une classe par l'enseignant
class AttendanceClassSelected extends AttendanceEvent {
  final ClassModel selectedClass;

  const AttendanceClassSelected(this.selectedClass);

  @override
  List<Object?> get props => [selectedClass];
}

/// Chargement des élèves d'une classe
class AttendanceLoadStudentsRequested extends AttendanceEvent {
  final String classId;

  const AttendanceLoadStudentsRequested(this.classId);

  @override
  List<Object?> get props => [classId];
}

// ========== GESTION COURS ==========

/// Détection automatique du cours selon l'heure actuelle
class AttendanceDetectCurrentCourse extends AttendanceEvent {
  final String classId;
  final DateTime dateTime;

  const AttendanceDetectCurrentCourse({
    required this.classId,
    required this.dateTime,
  });

  @override
  List<Object?> get props => [classId, dateTime];
}

/// Changement manuel de cours (dropdown)
class AttendanceCourseChanged extends AttendanceEvent {
  final CourseModel? course;

  const AttendanceCourseChanged(this.course);

  @override
  List<Object?> get props => [course];
}

// ========== GESTION PRÉSENCES ==========

/// Mise à jour du statut d'un élève (bouton spécifique)
class AttendanceStudentStatusUpdated extends AttendanceEvent {
  final String studentId;
  final AttendanceStatus status;

  const AttendanceStudentStatusUpdated({
    required this.studentId,
    required this.status,
  });

  @override
  List<Object?> get props => [studentId, status];
}

/// Toggle rapide : 1 clic = cycle Présent → Absent → Retard → Présent
class AttendanceToggleStatus extends AttendanceEvent {
  final String studentId;

  const AttendanceToggleStatus({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

/// Marquer tous les élèves comme présents (bouton rapide)
class AttendanceMarkAllPresent extends AttendanceEvent {
  const AttendanceMarkAllPresent();
}

/// Marquer tous les élèves comme absents (cas exceptionnel)
class AttendanceMarkAllAbsent extends AttendanceEvent {
  const AttendanceMarkAllAbsent();
}

// ========== SOUMISSION & DATE ==========

/// Validation et sauvegarde de l'appel
class AttendanceSubmitRequested extends AttendanceEvent {
  final DateTime date;

  const AttendanceSubmitRequested({required this.date});

  @override
  List<Object?> get props => [date];
}

/// Changement de date (appel rétrospectif ou anticipé)
class AttendanceDateChanged extends AttendanceEvent {
  final DateTime newDate;

  const AttendanceDateChanged(this.newDate);

  @override
  List<Object?> get props => [newDate];
}

// ========== ENUM & EXTENSIONS ==========

enum AttendanceStatus { present, absent, late }

extension AttendanceStatusExtension on AttendanceStatus {
  /// Valeur string pour la base de données
  String get value {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
    }
  }

  /// Créer depuis la base de données
  static AttendanceStatus fromString(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      default:
        return AttendanceStatus.present;
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Présent';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Retard';
    }
  }

  String get emoji {
    switch (this) {
      case AttendanceStatus.present:
        return '✓';
      case AttendanceStatus.absent:
        return '✗';
      case AttendanceStatus.late:
        return '⏰';
    }
  }

  String get colorHex {
    switch (this) {
      case AttendanceStatus.present:
        return '#14B8A6'; // Teal
      case AttendanceStatus.absent:
        return '#FB7185'; // Coral
      case AttendanceStatus.late:
        return '#F59E0B'; // Sunshine
    }
  }
}
