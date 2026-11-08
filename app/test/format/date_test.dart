import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soutrali/src/format/date.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  final now = DateTime(2026, 11, 8, 12);

  test('écrit une date récente à la manière d’un fil d’actualité', () {
    expect(publishedAgo(now.subtract(const Duration(seconds: 20)), now: now), 'à l’instant');
    expect(publishedAgo(now.subtract(const Duration(minutes: 12)), now: now), 'il y a 12 min');
    expect(publishedAgo(now.subtract(const Duration(hours: 3)), now: now), 'il y a 3 h');
    expect(publishedAgo(now.subtract(const Duration(days: 1)), now: now), 'il y a 1 jour');
    expect(publishedAgo(now.subtract(const Duration(days: 5)), now: now), 'il y a 5 jours');
  });

  test('affiche la date exacte au-delà d’une semaine', () {
    expect(publishedAgo(DateTime(2026, 10, 20), now: now), '20 octobre 2026');
    expect(publishedAgo(null), 'Date inconnue');
  });
}
