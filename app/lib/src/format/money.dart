import 'package:intl/intl.dart';

final NumberFormat _amounts = NumberFormat.decimalPattern('fr');

/// Montant en francs CFA écrit comme à Abidjan : « 5 000 FCFA ».
///
/// Le franc CFA n’a pas de centimes : le montant est toujours arrondi à
/// l’unité et groupé par milliers avec l’espace insécable du français.
String fcfa(num? amount) => amount == null ? '—' : '${fcfaPlain(amount)} FCFA';

/// Montant seul, sans unité : « 5 000 ».
String fcfaPlain(num? amount) => amount == null ? '' : _amounts.format(amount.round());

/// Montant compact pour un badge : « 5 000 F » au-delà de 10 000.
String fcfaShort(num? amount) {
  if (amount == null) {
    return '—';
  }

  final rounded = amount.round();

  return rounded >= 10000 ? '${fcfaPlain(rounded)} F' : '${fcfaPlain(rounded)} FCFA';
}
