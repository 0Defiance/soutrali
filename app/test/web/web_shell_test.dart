import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Le premier affichage se joue dans `web/index.html`, un fichier que les
  // tests de widgets ne traversent pas : c’est pourtant lui qui décide de ce
  // que l’utilisateur voit avant que le moteur Flutter n’ait téléchargé ses
  // 3,8 Mo de JavaScript. On vérifie donc ici les contrats du shell.
  final shell = File('web/index.html').readAsStringSync();

  test('le shell affiche un écran d’attente avant le moteur Flutter', () {
    expect(shell, contains('id="soutrali-splash"'));
    expect(shell, contains('Chargement de l’application…'));
    // Sans image ni police externe : l’écran doit tenir dans le seul HTML.
    expect(shell, contains('icons/Icon-192.png'));
  });

  test('l’écran d’attente s’efface à la première image de l’application', () {
    // Événement émis par le moteur Flutter après la première image rendue :
    // sans cet écouteur, l’écran d’attente resterait par-dessus l’application.
    expect(shell, contains("addEventListener('flutter-first-frame'"));
    expect(shell, contains('soutrali-splash-hidden'));
  });

  test('le bundle est préchargé pour ne pas attendre la fin du démarrage', () {
    expect(
      shell,
      contains('<link rel="preload" href="main.dart.js" as="script">'),
    );
    // Le moteur est servi par le CDN de Flutter : la résolution DNS et la
    // poignée de main TLS peuvent démarrer pendant le téléchargement du HTML.
    expect(shell, contains('href="https://www.gstatic.com" crossorigin'));
  });
}
