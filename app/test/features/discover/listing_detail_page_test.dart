import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/format/money.dart';
import 'package:soutrali/src/features/discover/listing_detail_page.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';

final _paid = Listing(
  id: 33,
  title: 'Réparation de ventilateurs et de petits électroménagers',
  description: 'Diagnostic offert et devis avant intervention, à domicile.',
  type: 'OFFRE',
  nature: 'REMUNEREE',
  commune: 'Yopougon',
  category: 'Réparations et dépannage',
  categoryIcon: 'tools',
  createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  authorId: 7,
  authorName: 'Équipe Soutrali',
  availability: 'Du lundi au samedi, après 15 h',
  budget: 6000,
);

final _volunteer = Listing(
  id: 34,
  title: 'Coup de main pour monter un meuble',
  description: 'Montage d’une armoire, outillage fourni.',
  type: 'OFFRE',
  nature: 'BENEVOLE',
  commune: 'Koumassi',
  category: 'Petites missions et coups de main',
  createdAt: DateTime.now().subtract(const Duration(days: 2)),
  authorId: 8,
  authorName: 'Awa Koné',
);

Future<void> _pump(WidgetTester tester, Listing listing) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        listingProvider.overrideWith((ref, id) async => listing),
        listingsProvider.overrideWith((ref, filters) async => <Listing>[]),
      ],
      child: MaterialApp(home: ListingDetailPage(listingId: listing.id)),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la fiche met le montant en avant et donne tous les repères', (tester) async {
    await _pump(tester, _paid);

    // Le montant est écrit en FCFA, pas en « F ».
    expect(find.byKey(const ValueKey('listing-amount')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('listing-amount'))).data,
      fcfa(6000),
    );
    expect(find.text('RÉMUNÉRATION ANNONCÉE'), findsOneWidget);

    // Lieu, disponibilité, date et référence : les quatre tuiles pratiques.
    expect(find.text('Lieu'), findsOneWidget);
    expect(find.text('Yopougon'), findsWidgets);
    expect(find.text('Disponibilité'), findsOneWidget);
    expect(find.text('Du lundi au samedi, après 15 h'), findsOneWidget);
    expect(find.text('Publication'), findsOneWidget);
    expect(find.text('il y a 3 h'), findsWidgets);
    expect(find.text('Référence'), findsOneWidget);
    expect(find.text('N° 33'), findsOneWidget);

    // L’auteur, les conseils et l’action principale sont présents.
    expect(find.text('Équipe Soutrali'), findsOneWidget);
    expect(find.text('Avant de vous engager'), findsOneWidget);
    expect(find.byKey(const ValueKey('listing-contact')), findsOneWidget);
  });

  testWidgets('une annonce bénévole affiche « Gratuit » et jamais un montant', (tester) async {
    await _pump(tester, _volunteer);

    expect(find.byKey(const ValueKey('listing-amount')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('listing-amount'))).data,
      'Gratuit',
    );
    expect(find.text('SERVICE BÉNÉVOLE'), findsOneWidget);
    expect(find.textContaining('FCFA'), findsNothing);
  });
}
