import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'features/account/my_listings_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/discover/discover_page.dart';
import 'features/discover/listing_detail_page.dart';
import 'features/messaging/messages_page.dart';
import 'theme/soutrali_theme.dart';

class SoutraliApp extends StatelessWidget {
  SoutraliApp({super.key});

  /// Routeur propre à chaque instance : l'état de navigation ne survit pas
  /// d'un test à l'autre (chaque `pumpWidget` repart de `/`).
  final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DiscoverPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) => ListingDetailPage(
          listingId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: '/mes-annonces', builder: (context, state) => const MyListingsPage()),
      GoRoute(path: '/messagerie', builder: (context, state) => const MessagesPage()),
      GoRoute(
        path: '/messagerie/:id',
        builder: (context, state) => MessagesPage(
          conversationId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Soutrali — L’entraide à porter de main',
      debugShowCheckedModeBanner: false,
      theme: SoutraliTheme.light,
      routerConfig: _router,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}