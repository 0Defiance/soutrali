/// Position GPS lue sur l’appareil.
class GeoPosition {
  const GeoPosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;

  /// Précision annoncée par le navigateur, en mètres (souvent l’écart
  /// réel de la position ; affichée pour rester honnête).
  final double? accuracyMeters;
}

/// Lieu reconnu par l’API Soutrali à partir d’une position GPS.
///
/// Renseigné par `GET /api/v1/geolocation` : pays, ville, commune, quartier
/// et zone, avec les coordonnées d’origine. `inServiceArea` est faux quand
/// la position est hors d’Abidjan — on ne présente alors aucun quartier.
class LocatedPlace {
  const LocatedPlace({
    required this.inServiceArea,
    required this.latitude,
    required this.longitude,
    this.country,
    this.city,
    this.communeId,
    this.commune,
    this.quartier,
    this.zone,
    this.label,
    this.distanceMeters,
    this.accuracyMeters,
  });

  final bool inServiceArea;
  final double latitude;
  final double longitude;
  final String? country;
  final String? city;
  final int? communeId;
  final String? commune;
  final String? quartier;
  final String? zone;
  final String? label;

  /// Écart entre la position et le centre du quartier reconnu.
  final int? distanceMeters;
  final int? accuracyMeters;

  String get shortLabel {
    if (!inServiceArea) {
      return 'Hors zone couverte';
    }

    return [commune, quartier].whereType<String>().where((part) => part.isNotEmpty).join(' · ');
  }

  factory LocatedPlace.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'];
    final commune = json['commune'];

    return LocatedPlace(
      inServiceArea: json['in_service_area'] as bool? ?? false,
      latitude: coordinates is Map<String, dynamic>
          ? (coordinates['latitude'] as num?)?.toDouble() ?? 0
          : 0,
      longitude: coordinates is Map<String, dynamic>
          ? (coordinates['longitude'] as num?)?.toDouble() ?? 0
          : 0,
      country: json['country'] as String?,
      city: json['city'] as String?,
      communeId: commune is Map<String, dynamic> ? (commune['id'] as num?)?.toInt() : null,
      commune: commune is Map<String, dynamic> ? commune['name'] as String? : null,
      quartier: json['quartier'] as String?,
      zone: json['zone'] as String?,
      label: json['label'] as String?,
      distanceMeters: (json['distance_m'] as num?)?.toInt(),
      accuracyMeters: (json['accuracy_m'] as num?)?.toInt(),
    );
  }

  /// Position à afficher, arrondie à cinq décimales (~1 m).
  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

/// Décision de l’utilisateur face à la proposition de localisation.
enum LocationDecision { pending, confirmed, refused }

/// Ce que l’application retient d’une session de localisation.
class LocationChoice {
  const LocationChoice({required this.decision, this.place});

  const LocationChoice.pending() : decision = LocationDecision.pending, place = null;

  final LocationDecision decision;
  final LocatedPlace? place;

  bool get isConfirmed => decision == LocationDecision.confirmed && place != null;

  double? get latitude => isConfirmed ? place!.latitude : null;

  double? get longitude => isConfirmed ? place!.longitude : null;
}
