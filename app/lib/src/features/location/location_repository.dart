import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../discover/listings_repository.dart';
import 'geolocation.dart';
import 'geolocation_stub.dart' if (dart.library.js_interop) 'geolocation_web.dart';

/// Lecture de la position de l’appareil (navigateur en web, rien ailleurs).
final geolocationServiceProvider = Provider<GeolocationService>(
  (ref) => createGeolocationService(),
);

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepository(ref.watch(dioProvider)),
);

/// Ce que l’utilisateur a décidé pour cette visite : jamais envoyé sans son
/// accord, et oublié au rechargement de la page.
class LocationChoiceNotifier extends Notifier<LocationChoice> {
  @override
  LocationChoice build() => const LocationChoice.pending();

  void confirm(LocatedPlace place) {
    state = LocationChoice(decision: LocationDecision.confirmed, place: place);
  }

  void refuse() {
    state = const LocationChoice(decision: LocationDecision.refused);
  }

  void reset() {
    state = const LocationChoice.pending();
  }
}

final locationChoiceProvider =
    NotifierProvider<LocationChoiceNotifier, LocationChoice>(LocationChoiceNotifier.new);

/// Résolution d’une position GPS par l’API Soutrali
/// (`GET /api/v1/geolocation`).
class LocationRepository {
  const LocationRepository(this._dio);

  final Dio _dio;

  Future<LocatedPlace> resolve(GeoPosition position) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/geolocation',
      queryParameters: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        if (position.accuracyMeters != null) 'accuracy': position.accuracyMeters!.round(),
      },
    );

    final data = response.data?['data'];

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Réponse de géolocalisation inattendue.');
    }

    return LocatedPlace.fromJson(data);
  }
}
