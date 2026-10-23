import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/app.dart';
import 'package:soutrali/src/features/auth/auth_repository.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';
import 'package:soutrali/src/features/discover/references_repository.dart';

/// Contrôleur d'authentification simulé : session ouverte sans réseau.
class _ConnectedAuthController extends AuthController {
  @override
  Future<AuthUser?> build() async => const AuthUser(
        id: 1,
        displayName: 'Awa Koné',
        email: 'awa@soutrali.ci',
        communeId: 1,
        communeName: 'Cocody',
      );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  bool connected = false,
  void Function(ListingFilters filters)? onFilters,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        listingsProvider.overrideWith((ref, filters) async {
          onFilters?.call(filters);
          return <Listing>[];
        }),
        categoriesProvider.overrideWith((ref) async => const [
          ReferenceItem(id: 1, name: 'Électricité'),
          ReferenceItem(id: 2, name: 'Ménage'),
        ]),
        communesProvider.overrideWith((ref) async => const [
          ReferenceItem(id: 1, name: 'Cocody'),
          ReferenceItem(id: 2, name: 'Marcory'),
        ]),
        if (connected) authProvider.overrideWith(() => _ConnectedAuthController()),
      ],
      child: SoutraliApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('annonce offers immediate and scheduled request choices', (tester) async {
    await _pumpApp(tester, connected: true);

    await tester.tap(find.text('Annonce'));
    await tester.pumpAndSettle();

    expect(find.text('Service spontané / immédiat'), findsOneWidget);
    expect(find.text('Service programmé'), findsOneWidget);

    await tester.tap(find.text('Service programmé'));
    await tester.pumpAndSettle();

    expect(find.text('Planifier un besoin'), findsOneWidget);
    expect(find.text('Date ou période souhaitée'), findsOneWidget);
    expect(find.text('Catégorie *'), findsOneWidget);
    expect(find.text('Commune *'), findsOneWidget);
    expect(find.text('Publier l’annonce'), findsOneWidget);
  });

  testWidgets('service offer can answer a need or list scheduled availability', (tester) async {
    await _pumpApp(tester, connected: true);

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
    ListingFilters? requestedFilters;
    await _pumpApp(tester, onFilters: (filters) => requestedFilters = filters);

    await tester.tap(find.text('Prestation de service'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Répondre à un besoin'));
    await tester.pumpAndSettle();

    expect(requestedFilters?.type, 'DEMANDE');
    expect(find.text('Annonces près de vous'), findsOneWidget);
  });

  testWidgets('guest is invited to sign in before publishing', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Annonce'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Service spontané / immédiat'));
    await tester.pumpAndSettle();

    expect(find.text('Connectez-vous pour publier'), findsOneWidget);

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    expect(find.text('Rejoindre Soutrali'), findsOneWidget);
  });
}
