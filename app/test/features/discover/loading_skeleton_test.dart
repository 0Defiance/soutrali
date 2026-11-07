import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/app.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/listing_skeleton.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';
import 'package:soutrali/src/features/discover/references_repository.dart';

void main() {
  testWidgets('des squelettes animés occupent la place des annonces en attente', (tester) async {
    tester.view.physicalSize = const Size(1300, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pending = Completer<List<Listing>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingsProvider.overrideWith((ref, filters) => pending.future),
          communesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
          categoriesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
        ],
        child: SoutraliApp(),
      ),
    );

    // Premier rendu + animation du reflet.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ListingSkeletonCard), findsWidgets);
    expect(find.text('Annonces près de vous'), findsOneWidget);

    pending.complete(const [
      Listing(
        id: 1,
        title: 'Réparation de vélo au quartier',
        description: 'Réglage des freins et des dérailleurs.',
        type: 'OFFRE',
        nature: 'REMUNEREE',
        commune: 'Cocody',
        category: 'Réparations et dépannage',
        createdAt: null,
      ),
    ]);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ListingSkeletonCard), findsNothing);
    expect(find.text('Réparation de vélo au quartier'), findsOneWidget);
  });

  test('la distance se lit en mètres puis en kilomètres', () {
    expect(formatDistanceKm(0), '0 m');
    expect(formatDistanceKm(0.48), '480 m');
    expect(formatDistanceKm(1.24), '1,2 km');
    expect(formatDistanceKm(12), '12,0 km');

    // Même commune : la distance au centre ne veut rien dire de plus.
    expect(listingDistanceLabel(0), 'à proximité');
    expect(listingDistanceLabel(0.48), 'à 480 m');
    expect(listingDistanceLabel(6.32), 'à 6,3 km');
  });
}
