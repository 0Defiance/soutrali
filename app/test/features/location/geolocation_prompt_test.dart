import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/app.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';
import 'package:soutrali/src/features/discover/references_repository.dart';
import 'package:soutrali/src/features/location/geolocation.dart';
import 'package:soutrali/src/features/location/geolocation_stub.dart';
import 'package:soutrali/src/features/location/location_repository.dart';

const _place = LocatedPlace(
  inServiceArea: true,
  latitude: 5.3971,
  longitude: -3.9729,
  country: 'Côte d’Ivoire',
  city: 'Abidjan',
  communeId: 6,
  commune: 'Cocody',
  quartier: 'Angré',
  zone: 'Abidjan Est',
  label: 'Côte d’Ivoire · Abidjan · Cocody — Angré',
  distanceMeters: 40,
  accuracyMeters: 22,
);

class _FixedGeolocation extends GeolocationService {
  @override
  bool get isSupported => true;

  @override
  Future<GeoPosition?> current() async => const GeoPosition(
        latitude: 5.3971,
        longitude: -3.9729,
        accuracyMeters: 22,
      );
}

class _FixedLocationRepository extends LocationRepository {
  _FixedLocationRepository() : super(Dio());

  @override
  Future<LocatedPlace> resolve(GeoPosition position) async => _place;
}

Future<void> _pumpApp(WidgetTester tester, List<ListingFilters> captured) async {
  tester.view.physicalSize = const Size(1300, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        geolocationServiceProvider.overrideWith((ref) => _FixedGeolocation()),
        locationRepositoryProvider.overrideWith((ref) => _FixedLocationRepository()),
        listingsProvider.overrideWith((ref, filters) async {
          captured.add(filters);
          return <Listing>[];
        }),
        communesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
        categoriesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
      ],
      child: SoutraliApp(),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la position est proposée puis appliquée après confirmation', (tester) async {
    final captured = <ListingFilters>[];

    await _pumpApp(tester, captured);

    // La fiche nomme le quartier, la ville, le pays et les mesures utiles.
    expect(find.byKey(const ValueKey('location-prompt')), findsOneWidget);
    expect(find.text('Trier les annonces par distance ?'), findsOneWidget);
    final sheet = find.byKey(const ValueKey('location-prompt'));

    expect(find.descendant(of: sheet, matching: find.text('Cocody — Angré')), findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Abidjan · Côte d’Ivoire')),
      findsOneWidget,
    );
    expect(find.text('± 22 m'), findsOneWidget);
    expect(find.text('à 40 m du centre'), findsOneWidget);
    expect(find.text('Abidjan Est'), findsOneWidget);
    expect(find.text('5.39710, -3.97290'), findsOneWidget);

    // Tant que l’on n’a pas confirmé, aucune coordonnée n’est envoyée.
    expect(captured.every((filters) => filters.latitude == null), isTrue);

    await tester.tap(find.byKey(const ValueKey('location-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('location-prompt')), findsNothing);

    final filters = captured.last;

    expect(filters.latitude, 5.3971);
    expect(filters.longitude, -3.9729);
    expect(filters.toQueryParameters()['latitude'], 5.3971);

    // L’en-tête affiche le lieu confirmé au lieu de « Abidjan ».
    expect(find.text('Cocody · Angré'), findsOneWidget);
  });

  testWidgets('un refus ne localise pas et ne renvoie pas la popup', (tester) async {
    final captured = <ListingFilters>[];

    await _pumpApp(tester, captured);

    await tester.tap(find.byKey(const ValueKey('location-refuse')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('location-prompt')), findsNothing);
    expect(captured.every((filters) => filters.latitude == null), isTrue);
    expect(find.text('Abidjan'), findsWidgets);
  });
}
