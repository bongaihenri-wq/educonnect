import 'package:flutter/services.dart';

class CsvTemplateService {
  static const Map<String, String> _templates = {
    'students_parents': 'assets/templates/students_parents_template.csv',
    'teachers': 'assets/templates/teachers_template.csv',
    'schedules': 'assets/templates/schedules_template.csv',
  };

  static Future<String> getTemplate(String type) async {
    final path = _templates[type];
    if (path == null) throw Exception('Template inconnu: $type');
    return await rootBundle.loadString(path);
  }

  static String getTemplateDescription(String type) {
    switch (type) {
      case 'students_parents':
        return '''Colonnes obligatoires:
- matricule: Identifiant unique de l'élève
- eleve_nom: Nom de famille de l'élève
- eleve_prenom: Prénom de l'élève
- classe: Nom de la classe (ex: 6ème A)
- parent_nom: Nom du parent
- parent_prenom: Prénom du parent
- parent_telephone: Téléphone avec indicatif (ex: +22501020304)''';
      case 'teachers':
        return '''Colonnes obligatoires:
- matiere: Matière enseignée (ex: Mathématiques)
- nom: Nom de l'enseignant
- prenom: Prénom de l'enseignant
- email: Email valide
- telephone: Téléphone avec indicatif''';
      case 'schedules':
        return '''Colonnes obligatoires:
- classe: Nom de la classe
- jour: Jour de la semaine (Lundi, Mardi...)
- heure_debut: HH:MM (ex: 08:00)
- heure_fin: HH:MM (ex: 10:00)
- matiere: Nom de la matière
- enseignant_email: Email de l'enseignant
- salle: Numéro ou nom de salle''';
      default:
        return '';
    }
  }
}