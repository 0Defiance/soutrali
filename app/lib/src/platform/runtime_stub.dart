import 'package:dio/dio.dart';

/// Variante **web** : aucun backend embarqué (l'API est distante), et la
/// session est portée par le navigateur (cookies automatiques + `Origin`
/// ajouté par le navigateur lui-même avec `withCredentials`).
Future<bool> prepareAppRuntime({required String apiBaseUrl}) async => true;

/// Aucun processus à arrêter sur le web.
Future<void> shutdownAppRuntime() async {}

/// Le Dio du web reste intact : l'adaptateur navigateur gère les cookies.
Dio configurePlatformDio(Dio dio, String apiBaseUrl) => dio;
