import 'package:intl/intl.dart';

/// Date d’une annonce, à la manière d’un fil d’actualité : « à l’instant »,
/// « il y a 12 min », « il y a 3 h », « il y a 5 jours », puis la date exacte
/// au-delà d’une semaine. `now` permet de figer l’horloge dans les tests.
String publishedAgo(DateTime? date, {DateTime? now}) {
  if (date == null) {
    return 'Date inconnue';
  }

  final moment = date.toLocal();
  final difference = (now ?? DateTime.now()).difference(moment);

  if (difference.isNegative || difference.inMinutes < 1) {
    return 'à l’instant';
  }

  if (difference.inMinutes < 60) {
    return 'il y a ${difference.inMinutes} min';
  }

  if (difference.inHours < 24) {
    return 'il y a ${difference.inHours} h';
  }

  if (difference.inDays < 7) {
    return 'il y a ${difference.inDays} ${difference.inDays == 1 ? 'jour' : 'jours'}';
  }

  return DateFormat('d MMMM yyyy', 'fr').format(moment);
}
