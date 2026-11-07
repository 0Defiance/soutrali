import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/app.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';
import 'package:soutrali/src/features/discover/references_repository.dart';

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

    expect(find.text('Réparation de vélos au quartier'), findsOneWidget);
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
}
