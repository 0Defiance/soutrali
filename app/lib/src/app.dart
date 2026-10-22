import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'features/discover/discover_page.dart';
import 'theme/soutrali_theme.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DiscoverPage()),
  ],
);

class SoutraliApp extends StatelessWidget {
  const SoutraliApp({super.key});

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