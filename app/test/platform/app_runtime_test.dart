import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/platform/app_runtime.dart';

void main() {
  test('configurePlatformDio ajoute l’en-tête Origin et un gestionnaire de cookies', () {
    const api = 'http://127.0.0.1:8123';

    final dio = configurePlatformDio(
      Dio(BaseOptions(baseUrl: api)),
      api,
    );

    // Sanctum n’ouvre une session que si Origin est un domaine stateful :
    // sans cet en-tête, login et inscription échoueraient hors navigateur.
    expect(dio.options.headers['Origin'], api);

    // Hors navigateur, personne ne retient le cookie de session à notre
    // place : le gestionnaire de cookies est obligatoire.
    expect(dio.interceptors.whereType<CookieManager>().length, 1);
  });

  test('prepareAppRuntime ne lance rien quand aucun backend n’est embarqué', () async {
    // Port fermé : la vérification échoue immédiatement ; l’exécutable de
    // test n’a aucun dossier backend/ à côté → aucun processus, résultat
    // « API externe » attendu.
    final ready = await prepareAppRuntime(
      apiBaseUrl: 'http://127.0.0.1:59999',
    );

    expect(ready, isFalse);
  });

  test('shutdownAppRuntime est sans effet quand rien n’a été démarré', () async {
    await expectLater(shutdownAppRuntime(), completes);
  });
}
