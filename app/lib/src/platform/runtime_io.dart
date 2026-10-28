import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Base du stockage des cookies de session, résolue au démarrage par
/// `prepareAppRuntime` : `%APPDATA%` sur Windows (comportement
/// historique), répertoire de l’application sur Android via
/// `path_provider` — `Directory.systemTemp` pointe vers
/// `/data/local/tmp`, non inscriptible depuis une application mobile.
/// Null sur le web (variante stub) et tant que `main()` ne l’a pas résolue.
String? cookieStorageBase;

/// Backend Laravel **embarqué** dans le paquet desktop (phase 2) :
/// `<dossier de l'exécutable>/backend` + PHP portable dans
/// `<dossier>/runtime/php/php.exe`.
///
/// Trois situations, dans cet ordre :
/// 1. le port de l'API répond déjà (backend démarré à l'écran précédent,
///    ou serveur de développement) → on le **réutilise** ;
/// 2. le dossier `backend/` n'existe pas à côté de l'exécutable (build de
///    développement, application mobile) → rien à faire, l'API est externe ;
/// 3. sinon : démarrage de `php artisan serve` et attente de la mise en
///    service (20 s maximum).
class EmbeddedBackend {
  EmbeddedBackend._();

  static final EmbeddedBackend instance = EmbeddedBackend._();

  Process? _process;

  /// Vrai si l'API répond (déjà en marche ou démarrée par nous).
  Future<bool> ensureRunning(String apiBaseUrl) async {
    if (await isHealthy(apiBaseUrl)) {
      return true;
    }

    final backend = Directory('${_executableDir()}/backend');
    final php = File('${_executableDir()}/runtime/php/php.exe');

    if (!await backend.exists() || !await php.exists()) {
      return false; // API externe (développement ou mobile) : rien à lancer.
    }

    final port = Uri.parse(apiBaseUrl).port;

    try {
      _process = await Process.start(
        php.path,
        ['artisan', 'serve', '--host=127.0.0.1', '--port=$port'],
        workingDirectory: backend.path,
      );
      // Les journaux du serveur de développement sont consommés pour ne
      // pas remplir le tuyau et figer le processus.
      _process!.stdout.listen((_) {}, onError: (_) {});
      _process!.stderr.listen((_) {}, onError: (_) {});
    } on ProcessException {
      return false;
    }

    for (var attempt = 0; attempt < 40; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (await isHealthy(apiBaseUrl)) {
        return true;
      }
    }

    return false;
  }

  /// Arrêt de l'arbre de processus que nous avons démarré (Windows :
  /// `taskkill /T` tue aussi le `php -S` enfant de `artisan serve`).
  Future<void> stop() async {
    final process = _process;
    _process = null;

    if (process == null) {
      return;
    }

    if (Platform.isWindows) {
      await Process.run('taskkill', ['/PID', '${process.pid}', '/T', '/F']);
    } else {
      process.kill();
    }
  }

  /// L'API répond-elle ? (route publique des référentiels, sans cookie.)
  Future<bool> isHealthy(String apiBaseUrl) async {
    try {
      final probe = Dio(
        BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(milliseconds: 800),
          receiveTimeout: const Duration(milliseconds: 800),
          headers: {'Accept': 'application/json'},
        ),
      );

      final response = await probe.get<void>('/api/v1/categories');

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String _executableDir() =>
      File(Platform.resolvedExecutable).parent.path.replaceAll(r'\', '/');
}

/// Démarre le backend embarqué si le paquet en contient un, et résout la
/// base de stockage des cookies de session (nécessaire avant la création
/// du premier client Dio).
/// Vrai si l'API est joignable après l'appel (toujours le cas en mode web
/// grâce à la variante stub, et en développement quand l'API externe tourne).
Future<bool> prepareAppRuntime({required String apiBaseUrl}) async {
  cookieStorageBase ??= await _resolveCookieStorageBase();

  return EmbeddedBackend.instance.ensureRunning(apiBaseUrl);
}

/// Base de stockage : Android d'abord (répertoire de l'application),
/// sinon la base historique Windows, sinon la temp du système.
Future<String> _resolveCookieStorageBase() async {
  if (Platform.isAndroid) {
    try {
      return (await getApplicationSupportDirectory()).path;
    } catch (_) {
      // Repli sur la base historique ci-dessous (NF-08 : jamais de crash).
    }
  }

  return Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
}

/// Arrêt demandé à la fermeture de l'application (meilleur effort).
Future<void> shutdownAppRuntime() => EmbeddedBackend.instance.stop();

/// Desktop / Android : la session repose sur des cookies que Dio ne gère
/// pas tout seul, et Sanctum n'ouvre une session que si l'en-tête `Origin`
/// correspond à un domaine déclaré `SANCTUM_STATEFUL_DOMAINS`.
Dio configurePlatformDio(Dio dio, String apiBaseUrl) {
  dio.options.headers['Origin'] = apiBaseUrl;

  // `flutter test` exécute les tests sous FakeAsync : les lectures
  // disque de `PersistCookieJar` ne s'y terminent jamais et laissée en
  // chargement éternel (pumpAndSettle en timeout). Sous le drapeau
  // `FLUTTER_TEST` on garde donc la même logique de cookies **en
  // mémoire** — aucune requête de test ne reçoit de vrai Set-Cookie du
  // client factice, la couverture des enregistrements reste donc de fait
  // l'affaire du test d'intégration. Le paquet de production garde le
  // jar fichier, seul garant d'une session conservée entre deux
  // lancements.
  final CookieJar jar;
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    jar = DefaultCookieJar();
  } else {
    jar = _sessionCookieJar();
  }

  dio.interceptors.add(CookieManager(jar));

  return dio;
}

/// Jar de cookies persistant du paquet de production : le stockage est
/// créé au besoin ; s’il n’est pas inscriptible (NF-08), on retombe sur
/// un jar mémoire — la session ne survivrait alors pas au redémarrage
/// plutôt que l’application de planter au lancement.
CookieJar _sessionCookieJar() {
  final base =
      cookieStorageBase ??
      Platform.environment['APPDATA'] ??
      Directory.systemTemp.path;
  final storage = '$base/Soutrali/cookies';

  try {
    Directory(storage).createSync(recursive: true);

    return PersistCookieJar(
      storage: FileStorage(storage),
      ignoreExpires: true,
    );
  } on FileSystemException {
    return DefaultCookieJar();
  }
}
