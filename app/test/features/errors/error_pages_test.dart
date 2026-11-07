import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soutrali/src/app.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/listing_detail_page.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';
import 'package:soutrali/src/features/discover/references_repository.dart';

void main() {
  testWidgets('une adresse inconnue affiche la page 404 dédiée', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingsProvider.overrideWith((ref, filters) async => <Listing>[]),
          communesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
          categoriesProvider.overrideWith((ref) async => const <ReferenceItem>[]),
        ],
        child: SoutraliApp(),
      ),
    );
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/adresse-inconnue');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('error-page')), findsOneWidget);
    expect(find.text('Page introuvable'), findsOneWidget);
    expect(find.text('Erreur 404'), findsOneWidget);
    expect(find.text('/adresse-inconnue'), findsOneWidget);
    expect(find.text('Retour à l’accueil'), findsOneWidget);
  });

  testWidgets('une panne du serveur affiche la page 500 avec réessai', (tester) async {
    final request = RequestOptions(path: '/api/v1/listings/7');
    final failure = DioException(
      requestOptions: request,
      response: Response<void>(requestOptions: request, statusCode: 500),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingProvider.overrideWith((ref, id) async => throw failure),
        ],
        child: const MaterialApp(home: ListingDetailPage(listingId: 7)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Erreur 500'), findsOneWidget);
    expect(find.text('Le serveur a rencontré un problème'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('une annonce retirée affiche la page 404 des annonces', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingProvider.overrideWith((ref, id) async => null),
        ],
        child: const MaterialApp(home: ListingDetailPage(listingId: 404)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Annonce introuvable'), findsOneWidget);
    expect(find.text('Erreur 404'), findsOneWidget);
    expect(find.text('/listing/404'), findsOneWidget);
  });

  testWidgets('une coupure réseau a son propre écran, pas un 500', (tester) async {
    final request = RequestOptions(path: '/api/v1/listings/9');
    final failure = DioException(
      requestOptions: request,
      type: DioExceptionType.connectionError,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingProvider.overrideWith((ref, id) async => throw failure),
        ],
        child: const MaterialApp(home: ListingDetailPage(listingId: 9)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connexion impossible'), findsOneWidget);
    expect(find.text('Erreur 404'), findsNothing);
    expect(find.text('Erreur 500'), findsNothing);
  });
}
