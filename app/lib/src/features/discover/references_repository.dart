import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'listings_repository.dart';

/// Élément d'un référentiel public : catégorie ou commune.
class ReferenceItem {
  const ReferenceItem({required this.id, required this.name, this.description, this.icon});

  final int id;
  final String name;
  final String? description;

  /// Clé d’icône du service (catégories uniquement) : voir
  /// `category_icons.dart` pour la traduction en icône.
  final String? icon;

  factory ReferenceItem.fromJson(Map<String, dynamic> json) => ReferenceItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        icon: json['icon'] as String?,
      );
}

final referencesRepositoryProvider = Provider<ReferencesRepository>(
  (ref) => ReferencesRepository(ref.watch(dioProvider)),
);

/// Communes actives du référentiel d’Abidjan (`GET /api/v1/communes`).
final communesProvider = FutureProvider<List<ReferenceItem>>(
  (ref) => ref.watch(referencesRepositoryProvider).communes(),
);

/// Catégories actives du référentiel (`GET /api/v1/categories`).
final categoriesProvider = FutureProvider<List<ReferenceItem>>(
  (ref) => ref.watch(referencesRepositoryProvider).categories(),
);

class ReferencesRepository {
  const ReferencesRepository(this._dio);

  final Dio _dio;

  Future<List<ReferenceItem>> communes() => _fetch('/api/v1/communes');

  Future<List<ReferenceItem>> categories() => _fetch('/api/v1/categories');

  Future<List<ReferenceItem>> _fetch(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    final rows = response.data?['data'];

    if (rows is! List) {
      throw const FormatException('Format de réponse API inattendu.');
    }

    return rows
        .whereType<Map<String, dynamic>>()
        .map(ReferenceItem.fromJson)
        .toList(growable: false);
  }
}
