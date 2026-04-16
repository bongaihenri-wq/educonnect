import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import du package
import 'app.dart';
import 'services/school_service.dart';

void main() async {
  // 1. S'assurer que les services Flutter sont prêts
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Charger les variables d'environnement depuis le fichier .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Erreur lors du chargement du fichier .env: $e");
  }

  // 3. Initialiser les données de locale pour intl (format de dates FR)
  await initializeDateFormatting('fr_FR', null);

  // 4. Initialisation Supabase avec les variables du .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '', 
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // 5. Restaurer la session école
  await SchoolService.restoreSession();

  // 6. Lancer l'application
  runApp(const EduConnectApp());
}