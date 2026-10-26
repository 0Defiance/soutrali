import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/app.dart';
import 'package:soutrali/src/features/account/account_repository.dart';
import 'package:soutrali/src/features/auth/auth_repository.dart';
import 'package:soutrali/src/features/discover/listing.dart';
import 'package:soutrali/src/features/discover/listings_repository.dart';
import 'package:soutrali/src/features/discover/references_repository.dart';

/// Session simulée avec un rôle donné (aucun réseau).
class _FakeAuthController extends AuthController {
  _FakeAuthController(this.role);

  final String? role;

  @override
  Future<AuthUser?> build() async => AuthUser(
        id: 1,
        displayName: 'Awa Koné',
        email: 'awa@soutrali.ci',
        communeName: 'Cocody',
        role: role,
      );
}

Future<void> _pumpApp(WidgetTester tester, {String? role}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        listingsProvider.overrideWith((ref, filters) async => <Listing>[]),
        categoriesProvider.overrideWith((ref) async => const [
              ReferenceItem(id: 1, name: 'Électricité'),
            ]),
        communesProvider.overrideWith((ref) async => const [
              ReferenceItem(id: 1, name: 'Cocody'),
            ]),
        myReportsProvider.overrideWith((ref) async => const <UserReport>[]),
        authProvider.overrideWith(() => _FakeAuthController(role)),
      ],
      child: SoutraliApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('canAccessAdminPanel', () {
    test('n’ouvre l’espace admin qu’aux rôles du back-office', () {
      expect(canAccessAdminPanel(null), isFalse);
      expect(
        canAccessAdminPanel(const AuthUser(id: 1, displayName: 'Aya', email: 'a@b.cd')),
        isFalse,
      );
      expect(
        canAccessAdminPanel(
          const AuthUser(id: 1, displayName: 'Aya', email: 'a@b.cd', role: 'UTILISATEUR'),
        ),
        isFalse,
      );
      expect(
        canAccessAdminPanel(
          const AuthUser(id: 1, displayName: 'Aya', email: 'a@b.cd', role: 'MODERATEUR'),
        ),
        isTrue,
      );
      expect(
        canAccessAdminPanel(
          const AuthUser(id: 1, displayName: 'Aya', email: 'a@b.cd', role: 'ADMINISTRATEUR'),
        ),
        isTrue,
      );
    });
  });

  testWidgets('an administrator sees the Espace admin entry in the account menu', (tester) async {
    await _pumpApp(tester, role: 'ADMINISTRATEUR');

    await tester.tap(find.byTooltip('Menu du compte'));
    await tester.pumpAndSettle();

    expect(find.text('Espace admin'), findsOneWidget);
    expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);
  });

  testWidgets('a regular member gets no admin entry', (tester) async {
    await _pumpApp(tester, role: 'UTILISATEUR');

    await tester.tap(find.byTooltip('Menu du compte'));
    await tester.pumpAndSettle();

    expect(find.text('Espace admin'), findsNothing);
  });

  testWidgets('the profile dialog offers the admin console to staff only', (tester) async {
    await _pumpApp(tester, role: 'ADMINISTRATEUR');

    await tester.tap(find.byTooltip('Menu du compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mon profil'));
    await tester.pumpAndSettle();

    expect(find.text('Espace admin'), findsOneWidget);

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    await _pumpApp(tester, role: 'MODERATEUR');
    await tester.tap(find.byTooltip('Menu du compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mon profil'));
    await tester.pumpAndSettle();

    expect(find.text('Espace admin'), findsOneWidget);
  });
}
