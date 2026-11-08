import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/app.dart';
import 'package:soutrali/src/features/discover/category_icons.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';
import 'package:soutrali/src/features/discover/references_repository.dart';

void main() {
  test('categoryIcon translates a service key and falls back safely', () {
    expect(categoryIcon('plumbing'), Icons.plumbing);
    expect(categoryIcon('education'), Icons.school);
    expect(categoryIcon('inconnue'), Icons.category);
    expect(categoryIcon(null), Icons.category);
  });

  testWidgets('shows every service with its icon and filters the results on tap', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ListingFilters? requested;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingsProvider.overrideWith((ref, filters) async {
            requested = filters;
            return <Listing>[];
          }),
          communesProvider.overrideWith((ref) async => const [
                ReferenceItem(id: 1, name: 'Abobo'),
              ]),
          categoriesProvider.overrideWith((ref) async => const [
                ReferenceItem(
                  id: 3,
                  name: 'Éducation et cours',
                  icon: 'education',
                  listingsCount: 4,
                ),
                ReferenceItem(id: 9, name: 'Plomberie et sanitaire', icon: 'plumbing'),
              ]),
        ],
        child: SoutraliApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Le bloc « Tous les services » présente chaque service et son icône.
    expect(find.text('Tous les services'), findsOneWidget);
    expect(find.text('Éducation et cours'), findsOneWidget);
    expect(find.byIcon(Icons.school), findsWidgets);
    expect(find.byIcon(Icons.plumbing), findsWidgets);

    // Chaque service annonce son nombre d’annonces…
    expect(find.text('4 annonces'), findsOneWidget);
    expect(find.text('Aucune annonce'), findsOneWidget);

    // …et toutes les tuiles ont exactement la même taille : la grille est
    // régulière, quel que soit le nom du service (8 nov. 2026).
    final first = tester.getSize(find.byKey(const ValueKey('service-3')));
    final second = tester.getSize(find.byKey(const ValueKey('service-9')));
    expect(first, second);
    expect(first.height, 72);

    // Un service choisi devient le filtre de catégorie des résultats ; le
    // visiteur fait défiler jusqu’au bloc des services avant de cliquer.
    await tester.ensureVisible(find.text('Plomberie et sanitaire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plomberie et sanitaire'));
    await tester.pumpAndSettle();

    expect(requested, isNotNull);
    expect(requested!.category, 9);
    expect(requested!.toQueryParameters(), {'category': 9});
  });
}
