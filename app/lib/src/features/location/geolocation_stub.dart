import 'geolocation.dart';

/// Service de position des plateformes sans navigateur (Windows, Android,
/// tests) : aucune position n’est disponible, l’application ne demande donc
/// rien et ne s’appuie sur aucune coordonnée.
class GeolocationService {
  const GeolocationService();

  bool get isSupported => false;

  Future<GeoPosition?> current() async => null;
}

GeolocationService createGeolocationService() => const GeolocationService();
