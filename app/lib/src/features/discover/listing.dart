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
    this.authorName,
    this.availability,
    this.budget,
  });

  final int id;
  final String title;
  final String description;
  final String type;
  final String nature;
  final String commune;
  final String category;
  final DateTime? createdAt;
  final String? authorName;
  final String? availability;
  final num? budget;

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
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      authorName: author is Map<String, dynamic>
          ? author['display_name'] as String?
          : json['author_name'] as String?,
      availability: json['availability'] as String?,
      budget: json['budget'] as num?,
    );
  }
}

class ListingFilters {
  const ListingFilters({
    this.query = '',
    this.commune = '',
    this.type = '',
    this.nature = '',
  });

  final String query;
  final String commune;
  final String type;
  final String nature;

  Map<String, dynamic> toQueryParameters() => {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (commune.isNotEmpty) 'commune': commune,
        if (type.isNotEmpty) 'type': type,
        if (nature.isNotEmpty) 'nature': nature,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingFilters &&
          query == other.query &&
          commune == other.commune &&
          type == other.type &&
          nature == other.nature;

  @override
  int get hashCode => Object.hash(query, commune, type, nature);
}