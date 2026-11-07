class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.nature,
    required this.commune,
    required this.category,
    required this.createdAt,
    this.categoryIcon,
    this.authorId,
    this.authorName,
    this.availability,
    this.budget,
    this.distanceKm,
  });

  final int id;
  final String title;
  final String description;
  final String type;
  final String nature;
  final String commune;
  final String category;

  /// Clé d’icône de la catégorie (absente si l’API ne l’envoie pas).
  final String? categoryIcon;
  final DateTime? createdAt;
  final int? authorId;
  final String? authorName;
  final String? availability;
  final num? budget;

  /// Distance au centre de la commune, uniquement quand l’API a reçu la
  /// position confirmée de l’utilisateur. `null` sinon.
  final double? distanceKm;

  factory Listing.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final commune = json['commune'];
    final author = json['author'];

    return Listing(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'OFFRE',
      nature: json['nature'] as String? ?? 'BENEVOLE',
      commune: commune is Map<String, dynamic>
          ? commune['name'] as String? ?? ''
          : json['commune_name'] as String? ?? '',
      category: category is Map<String, dynamic>
          ? category['name'] as String? ?? ''
          : json['category_name'] as String? ?? '',
      categoryIcon: category is Map<String, dynamic> ? category['icon'] as String? : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      authorId: author is Map<String, dynamic> ? (author['id'] as num?)?.toInt() : null,
      authorName: author is Map<String, dynamic>
          ? author['display_name'] as String?
          : json['author_name'] as String?,
      availability: json['availability'] as String?,
      // Tolère un budget renvoyé en chaîne ("5000.00") par l'API.
      budget: json['budget'] is num ? json['budget'] as num : num.tryParse('${json['budget']}'),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}

/// Distance lisible : mètres en dessous du kilomètre, puis kilomètres à
/// une décimale (« 480 m », « 1,2 km »), avec la virgule française.
String formatDistanceKm(double kilometers) {
  if (kilometers < 1) {
    return '${(kilometers * 1000).round()} m';
  }

  return '${kilometers.toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Formulation de la distance sur une carte : une annonce de la même commune
/// est « à proximité » (la distance est mesurée au centre de la commune), les
/// autres sont situées en mètres ou en kilomètres.
String listingDistanceLabel(double kilometers) =>
    kilometers < 0.1 ? 'à proximité' : 'à ${formatDistanceKm(kilometers)}';

class ListingFilters {
  const ListingFilters({
    this.query = '',
    this.commune = '',
    this.type = '',
    this.nature = '',
    this.category,
    this.latitude,
    this.longitude,
  });

  final String query;
  final String commune;
  final String type;
  final String nature;

  /// Identifiant de catégorie, ou `null` pour « toutes ».
  final int? category;

  /// Position confirmée de l’utilisateur : les annonces sont alors triées
  /// de la plus proche à la plus lointaine (7 nov. 2026).
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toQueryParameters() => {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (commune.isNotEmpty) 'commune': commune,
        if (category != null) 'category': category,
        if (type.isNotEmpty) 'type': type,
        if (nature.isNotEmpty) 'nature': nature,
        if (latitude != null && longitude != null) 'latitude': latitude,
        if (latitude != null && longitude != null) 'longitude': longitude,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingFilters &&
          query == other.query &&
          commune == other.commune &&
          type == other.type &&
          nature == other.nature &&
          category == other.category &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(query, commune, type, nature, category, latitude, longitude);
}