import 'package:flutter_test/flutter_test.dart';
import 'package:soutrali/src/format/money.dart';

/// Les espaces du format français sont insécables : on les normalise avant
/// de comparer, sinon le test dépendrait du caractère exact choisi par intl.
String _plain(String value) => value.replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');

void main() {
  test('écrit un montant en FCFA comme à Abidjan', () {
    expect(_plain(fcfa(5000)), '5 000 FCFA');
    expect(_plain(fcfa(250)), '250 FCFA');
    expect(_plain(fcfa(1500000)), '1 500 000 FCFA');
    expect(fcfa(null), '—');
  });

  test('arrondit au franc : le FCFA n’a pas de centimes', () {
    expect(_plain(fcfa(5000.4)), '5 000 FCFA');
    expect(_plain(fcfa(5000.6)), '5 001 FCFA');
  });

  test('raccourcit les gros montants pour les badges', () {
    expect(_plain(fcfaShort(5000)), '5 000 FCFA');
    expect(_plain(fcfaShort(25000)), '25 000 F');
  });
}
