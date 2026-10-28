import 'package:dio/dio.dart';

/// Déclarée dans les deux variantes (web et io) pour que les symboles
/// partagés soient visibles quel que soit le choix de
/// l’export conditionnel. **Toujours null sur le web** : le navigateur
/// porte les cookies, il n’y a rien à stocker côté Dart.
String? cookieStorageBase;

/// Variante **web** : aucun backend embarqué (l'API est distante), et la
/// session est portée par le navigateur (cookies automatiques + `Origin`
/// ajouté par le navigateur lui-même avec `withCredentials`).
Future<bool> prepareAppRuntime({required String apiBaseUrl}) async => true;

/// Aucun processus à arrêter sur le web.
Future<void> shutdownAppRuntime() async {}

/// Le Dio du web reste intact : l'adaptateur navigateur gère les cookies.
Dio configurePlatformDio(Dio dio, String apiBaseUrl) => dio;
