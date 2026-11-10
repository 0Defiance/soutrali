import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/app.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/listing_detail_page.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';
import 'package:soutrali/src/features/discover/references_repository.dart';
import 'package:soutrali/src/platform/app_download.dart';
import 'package:soutrali/src/theme/soutrali_theme.dart';

/// Polices de la charte : sans elles, le test mesure la police de secours,
/// plus large que Manrope, et signale des débordements que le site n’a pas.
Future<void> _loadFonts() async {
  const families = {
    'Manrope': 'assets/fonts/Manrope.ttf',
    'Source Sans 3': 'assets/fonts/SourceSans3.ttf',
  };

  for (final entry in families.entries) {
    final bytes = File(entry.value).readAsBytesSync();

    await (FontLoader(entry.key)
          ..addFont(Future.value(ByteData.view(bytes.buffer))))
        .load();
  }
}

void main() {
  testWidgets('le hero compte les services, les annonces et les communes', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingsProvider.overrideWith((ref, filters) async => <Listing>[]),
          communesProvider.overrideWith((ref) async => const [
                ReferenceItem(id: 1, name: 'Abobo'),
                ReferenceItem(id: 2, name: 'Cocody'),
                ReferenceItem(id: 3, name: 'Yopougon'),
                // Zone de saisie, pas une commune : elle ne compte pas.
                ReferenceItem(id: 4, name: 'Plusieurs communes', isZone: true),
              ]),
          categoriesProvider.overrideWith((ref) async => const [
                ReferenceItem(id: 1, name: 'Éducation et cours', icon: 'education', listingsCount: 3),
                ReferenceItem(id: 2, name: 'Plomberie et sanitaire', icon: 'plumbing', listingsCount: 1),
              ]),
        ],
        child: SoutraliApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Trois repères réels, pas des chiffres écrits en dur dans la page.
    expect(find.text('services couverts'), findsOneWidget);
    expect(find.text('annonces en ligne'), findsOneWidget);
    expect(find.text('communes d’Abidjan'), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('hero-stat-services couverts')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('hero-stat-annonces en ligne')),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('hero-stat-communes d’Abidjan')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    // Grille vide : la section l'annonce au lieu de laisser un blanc.
    expect(find.byKey(const ValueKey('results-count')), findsOneWidget);
    expect(find.text('aucun résultat'), findsOneWidget);
  });

  testWidgets('une carte annonce affiche son bandeau de service et sa distance', (tester) async {
    tester.view.physicalSize = const Size(1300, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingsProvider.overrideWith(
            (ref, filters) async => const [
              Listing(
                id: 7,
                title: 'Réparation de vélos au quartier',
                description: 'Diagnostic offert et devis avant intervention.',
                type: 'OFFRE',
                nature: 'REMUNEREE',
                commune: 'Yopougon',
                category: 'Réparations et dépannage',
                categoryIcon: 'repair',
                distanceKm: 2.4,
                createdAt: null,
              ),
            ],
          ),
          communesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
          categoriesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
        ],
        child: SoutraliApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Le titre apparaît deux fois : la carte de la grille et la vitrine du
    // hero, qui reprend elle aussi de vraies annonces.
    expect(find.text('Réparation de vélos au quartier'), findsWidgets);
    // « Offre » et « Rémunérée » existent aussi dans les filtres : la carte
    // doit en tout cas porter les deux étiquettes de lecture.
    expect(find.text('Offre'), findsWidgets);
    expect(find.text('Rémunérée'), findsWidgets);
    final distance = tester.widget<Text>(find.byKey(const ValueKey('listing-distance')));
    expect(distance.data, 'à 2,4 km');
    // Le bandeau reprend l'icône de charte du service.
    expect(find.byIcon(Icons.handyman), findsWidgets);
    // Une seule annonce : le compteur de la section le dit.
    expect(find.text('1 résultat'), findsOneWidget);
  });

  testWidgets('le pied de page propose l’APK Android servi par le site', (tester) async {
    await _loadFonts();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var downloads = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingsProvider.overrideWith((ref, filters) async => <Listing>[]),
          communesProvider.overrideWith((ref) async => const [
                ReferenceItem(id: 1, name: 'Cocody'),
              ]),
          categoriesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
          apkDownloaderProvider.overrideWith(
            (ref) => () async {
              downloads++;
              return true;
            },
          ),
        ],
        child: SoutraliApp(),
      ),
    );
    await tester.pumpAndSettle();

    final download = find.byKey(const ValueKey('download-apk'));

    // Le bandeau vit en bas de la vitrine, après les annonces.
    await tester.scrollUntilVisible(
      download,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Soutrali pour Android'), findsOneWidget);
    expect(find.text('Télécharger l’APK'), findsOneWidget);

    // Le logo Soutrali est l’image principale de l’option, et les deux
    // pictogrammes qui l’accompagnent sont réellement dessinés : l’Android
    // et la flèche de téléchargement, pas un carré vide.
    expect(find.byKey(const ValueKey('android-banner-logo')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('android-banner-logo')),
        matching: find.byWidgetPredicate(
          (widget) => widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == 'assets/brand/soutrali-logo.png',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('android-banner-icon')),
        matching: find.byIcon(Icons.android),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('download-banner-icon')),
        matching: find.byIcon(Icons.download_rounded),
      ),
      findsOneWidget,
    );

    // Le fichier est servi par le site lui-même, sur la même origine que l’API.
    expect(Uri.parse(apkDownloadUrl).path, '/downloads/soutrali.apk');
    expect(apkDownloadUrl, startsWith(apiBaseUrl));

    // Un appui demande bien l’ouverture du fichier, une seule fois.
    expect(downloads, 0);

    // Toute la carte est cliquable, pas seulement le bouton.
    await tester.tap(find.text('Soutrali pour Android'));
    await tester.pumpAndSettle();

    expect(downloads, 1);

    // Le bouton reste le geste explicite, et ne déclenche qu’un téléchargement.
    await tester.tap(download);
    await tester.pumpAndSettle();

    expect(downloads, 2);
  });

  testWidgets('le hero montre de vraies annonces, cliquables et renouvelées', (tester) async {
    // Trois offres et trois demandes. Les annonces 2 et 3 portent le même
    // service dans la même commune : elles ne doivent jamais s’afficher
    // ensemble, sinon l’écran montre deux fois la même proposition.
    const communesByIndex = ['Cocody', 'Yopougon', 'Abobo', 'Abobo', 'Treichville', 'Marcory'];
    final pool = [
      for (var index = 0; index < 6; index++)
        Listing(
          id: 200 + index,
          title: 'Service réel numéro $index',
          description: 'Annonce publiée par un habitant d’Abidjan.',
          type: index.isEven ? 'OFFRE' : 'DEMANDE',
          nature: 'BENEVOLE',
          commune: communesByIndex[index],
          category: index < 2 ? 'Couture, beauté et bien-être' : 'Réparations et dépannage',
          categoryIcon: 'repair',
          createdAt: DateTime(2026, 11, 10, 9),
        ),
    ];

    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingsProvider.overrideWith((ref, filters) async => pool),
          listingProvider.overrideWith((ref, id) async {
            for (final listing in pool) {
              if (listing.id == id) {
                return listing;
              }
            }
            return null;
          }),
          communesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
          categoriesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
        ],
        child: SoutraliApp(),
      ),
    );
    await tester.pumpAndSettle();

    /// Les deux cartes de la vitrine, repérées par leur clé d’annonce.
    final showcase = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('hero-listing-'),
    );
    List<int> shownIds() => [
          for (final widget in tester.widgetList<Widget>(showcase))
            int.parse((widget.key! as ValueKey<String>).value.split('-').last),
        ];

    Listing listingOf(int id) => pool.firstWhere((listing) => listing.id == id);

    /// Une carte du hero est verte si elle est une offre, orange si elle est
    /// une demande ; le libellé porte la couleur de la nature.
    void expectNatureColours(List<int> ids) {
      final types = ids.map((id) => listingOf(id).type).toList();
      expect(types, containsAll(['OFFRE', 'DEMANDE']));

      for (final id in ids) {
        final isRequest = listingOf(id).type == 'DEMANDE';
        final badge = tester.widget<Text>(
          find.descendant(
            of: find.byKey(ValueKey('hero-listing-$id')),
            matching: find.text(isRequest ? 'Demande' : 'Offre'),
          ),
        );

        expect(badge.style?.color, isRequest ? SoutraliColors.orange : SoutraliColors.green);
      }
    }

    /// Deux annonces du même service dans la même commune feraient doublon :
    /// la vitrine préfère deux services différents.
    void expectNoDuplicateService(List<int> ids) {
      final pairs = {
        for (final id in ids) '${listingOf(id).category}|${listingOf(id).commune}',
      };
      expect(pairs, hasLength(ids.length));
      expect(listingOf(ids[0]).category, isNot(listingOf(ids[1]).category));
    }

    var shown = shownIds();
    expect(shown, hasLength(2));
    // Ce sont des annonces du vivier, pas deux exemples figés.
    expect(pool.map((listing) => listing.id), containsAll(shown));
    expect(find.text('Réparation de ventilateurs'), findsNothing);

    // Une offre en vert et une demande en orange, jamais deux fois le même
    // service.
    expectNatureColours(shown);
    expectNoDuplicateService(shown);

    // Cinq minutes plus tard, la vitrine a changé de paire — et reste juste.
    await tester.pump(const Duration(minutes: 5));
    await tester.pump();

    var rotated = shownIds();
    expect(rotated, hasLength(2));
    expect(pool.map((listing) => listing.id), containsAll(rotated));
    expect(rotated, isNot(shown));
    expectNatureColours(rotated);
    expectNoDuplicateService(rotated);

    // Plusieurs renouvellements d’affilée : la règle tient à chaque fois.
    for (var turn = 0; turn < 3; turn++) {
      await tester.pump(const Duration(minutes: 5));
      await tester.pump();
      final next = shownIds();
      expect(next, hasLength(2));
      expectNatureColours(next);
      expectNoDuplicateService(next);
      rotated = next;
    }

    shown = rotated;

    // La carte ouvre la fiche de son annonce : le bouton n’est pas décoratif.
    await tester.tap(find.byKey(ValueKey('hero-listing-${shown.first}')));
    await tester.pumpAndSettle();

    expect(find.byType(ListingDetailPage), findsOneWidget);
    expect(
      find.text(pool.firstWhere((listing) => listing.id == shown.first).title),
      findsWidgets,
    );
  });
}
