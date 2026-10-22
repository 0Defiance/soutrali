import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soutrali/src/app.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';

void main() {
  testWidgets('annonce offers immediate and scheduled request choices', (tester) async {
    await tester.view.setPhysicalSize(const Size(1200, 900));
    await tester.view.setDevicePixelRatio(1);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingsProvider(const ListingFilters()).overrideWith((ref) async => []),
        ],
        child: const SoutraliApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Annonce'));
    await tester.pumpAndSettle();

    expect(find.text('Service spontané / immédiat'), findsOneWidget);
    expect(find.text('Service programmé'), findsOneWidget);

    await tester.tap(find.text('Service programmé'));
    await tester.pumpAndSettle();

    expect(find.text('Planifier un besoin'), findsOneWidget);
    expect(find.text('Date ou période souhaitée'), findsOneWidget);
  });

  testWidgets('service offer can answer a need or list scheduled availability', (tester) async {
    await tester.view.setPhysicalSize(const Size(1200, 900));
    await tester.view.setDevicePixelRatio(1);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingsProvider(const ListingFilters()).overrideWith((ref) async => []),
        ],
        child: const SoutraliApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prestation de service'));
    await tester.pumpAndSettle();

    expect(find.text('Répondre à un besoin'), findsOneWidget);
    expect(find.text('Proposer mes services de manière programmée'), findsOneWidget);

    await tester.tap(find.text('Proposer mes services de manière programmée'));
    await tester.pumpAndSettle();

    expect(find.text('Décrire mes disponibilités'), findsOneWidget);
    expect(find.text('Mes jours et horaires disponibles'), findsOneWidget);
  });

  testWidgets('answering a need opens the request results', (tester) async {
    await tester.view.setPhysicalSize(const Size(1200, 900));
    await tester.view.setDevicePixelRatio(1);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ListingFilters? requestedFilters;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingsProvider(const ListingFilters()).overrideWith((ref, filters) async {
            requestedFilters = filters;
            return [];
          }),
        ],
        child: const SoutraliApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prestation de service'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Répondre à un besoin'));
    await tester.pumpAndSettle();

    expect(requestedFilters?.type, 'DEMANDE');
    expect(find.text('Annonces près de vous'), findsOneWidget);
  });
}