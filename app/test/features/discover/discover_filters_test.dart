import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/app.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';
import 'package:soutrali/src/features/discover/references_repository.dart';

void main() {
  testWidgets('selecting a commune and a category filters the results', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
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
                ReferenceItem(id: 6, name: 'Cocody'),
              ]),
          categoriesProvider.overrideWith((ref) async => const [
                ReferenceItem(id: 3, name: 'Éducation et cours'),
                ReferenceItem(id: 5, name: 'Informatique et numérique'),
              ]),
        ],
        child: SoutraliApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Toutes les communes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cocody').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Toutes les catégories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Éducation et cours').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rechercher'));
    await tester.pumpAndSettle();

    expect(requested, isNotNull);
    expect(requested!.commune, 'Cocody');
    expect(requested!.category, 3);
    expect(requested!.toQueryParameters(), {'commune': 'Cocody', 'category': 3});
  });
}
