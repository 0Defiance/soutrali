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
                ReferenceItem(id: 3, name: 'Éducation et cours', icon: 'education'),
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

    // Un service choisi devient le filtre de catégorie des résultats.
    await tester.tap(find.text('Plomberie et sanitaire'));
    await tester.pumpAndSettle();

    expect(requested, isNotNull);
    expect(requested!.category, 9);
    expect(requested!.toQueryParameters(), {'category': 9});
  });
}
