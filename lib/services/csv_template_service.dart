// lib/services/csv_template_service.dart
class CsvTemplateService {
  static String getTemplate(String type) {
    switch (type) {
      case 'students_parents':
        return '''matricule,eleve_nom,eleve_prenom,classe,parent_nom,parent_prenom,parent_telephone
ABC123,Kouassi,Jean,6eme A,Kouassi,Marie,+2250506224449
DEF456,Konan,Aline,6eme B,Konan,Pierre,+2250506224450''';
      
      case 'teachers':
        return '''nom,prenom,telephone,matiere
Dupont,Jean,+2250123456789,Mathematiques
Martin,Sophie,+2250123456790,Francais''';
      
      case 'schedules':
        return '''classe,jour,heure_debut,heure_fin,matiere,enseignant_telephone,salle
6eme A,lundi,08:00,10:00,Mathematiques,+2250123456789,Salle 101
6eme A,lundi,10:00,12:00,Francais,+2250123456790,Salle 102''';
      
      default:
        throw Exception('Type inconnu: $type');
    }
  }

  static String getTemplateDescription(String type) {
    switch (type) {
      case 'students_parents':
        return 'Importez les eleves et leurs parents.\nLe parent est cree automatiquement avec le telephone comme identifiant.\nMot de passe = matricule de l\'eleve.';
      
      case 'teachers':
        return 'Importez les enseignants.\nTelephone = identifiant de connexion.\nMot de passe = Initiale + Nom en majuscule (ex: JDUPONT).';
      
      case 'schedules':
        return 'Importez l\'emploi du temps.\nUtilisez le telephone de l\'enseignant (pas l\'email).\nL\'enseignant doit deja etre importe.\nFormat heure: HH:MM (ex: 08:00) ou HH:MM:SS (ex: 08:00:00)';
      
      default:
        return '';
    }
  }
  
  /// Retourne les headers attendus pour un type
  static List<String> getExpectedHeaders(String type) {
    switch (type) {
      case 'students_parents':
        return ['matricule', 'eleve_nom', 'eleve_prenom', 'classe', 'parent_nom', 'parent_prenom', 'parent_telephone'];
      case 'teachers':
        return ['nom', 'prenom', 'telephone', 'matiere'];
      case 'schedules':
        return ['classe', 'jour', 'heure_debut', 'heure_fin', 'matiere', 'enseignant_telephone', 'salle'];
      default:
        return [];
    }
  }
}