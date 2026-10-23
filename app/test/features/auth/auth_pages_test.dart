import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/app.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        listingsProvider.overrideWith((ref, filters) async => <Listing>[]),
      ],
      child: SoutraliApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login page validates required fields', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Connexion'));
    await tester.pumpAndSettle();

    expect(find.text('Heureux de vous revoir'), findsOneWidget);

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail obligatoire.'), findsOneWidget);
    expect(find.text('Mot de passe obligatoire.'), findsOneWidget);
  });

  testWidgets('login page rejects malformed email', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Connexion'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'pas-un-email');
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Saisissez un e-mail valide.'), findsOneWidget);
  });

  testWidgets('register page checks password confirmation', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('S’inscrire'));
    await tester.pumpAndSettle();

    expect(find.text('Rejoindre Soutrali'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Awa Koné');
    await tester.enterText(fields.at(1), 'awa@soutrali.ci');
    await tester.enterText(fields.at(2), 'secret123');
    await tester.enterText(fields.at(3), 'different123');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Les mots de passe ne correspondent pas.'), findsOneWidget);
  });

  testWidgets('login page links to registration and vice versa', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Connexion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pas encore de compte ? Créer un compte'));
    await tester.pumpAndSettle();

    expect(find.text('Rejoindre Soutrali'), findsOneWidget);

    await tester.tap(find.text('Déjà un compte ? Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Heureux de vous revoir'), findsOneWidget);
  });
}
