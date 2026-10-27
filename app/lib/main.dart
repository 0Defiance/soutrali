import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'src/app.dart';
import 'src/features/discover/listings_repository.dart';
import 'src/platform/app_runtime.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');

  // Version empaquetée (desktop, phase 2) : démarre le backend local
  // embarqué s'il existe à côté de l'exécutable ; no-op sur le web et en
  // développement quand l'API externe répond déjà.
  await prepareAppRuntime(apiBaseUrl: apiBaseUrl);

  // À la fermeture de la fenêtre (détachage du moteur), on arrête le
  // serveur que nous avons démarré (meilleur effort ; un processus
  // orphelin est réutilisé au lancement suivant, cf. EmbeddedBackend).
  AppLifecycleListener(onDetach: shutdownAppRuntime);

  runApp(ProviderScope(child: SoutraliApp()));
}
