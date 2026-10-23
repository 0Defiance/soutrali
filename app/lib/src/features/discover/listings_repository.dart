import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'listing.dart';

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: _apiBaseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 12),
    headers: const {'Accept': 'application/json'},
    extra: const {'withCredentials': true},
  ));
});

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(ref.watch(dioProvider));
});

final listingsProvider = FutureProvider.family<List<Listing>, ListingFilters>((ref, filters) {
  return ref.watch(listingsRepositoryProvider).search(filters);
});

/// Détail d’une annonce (`GET /api/v1/listings/{id}`) ; `null` si absente.
final listingProvider = FutureProvider.family<Listing?, int>((ref, id) {
  return ref.watch(listingsRepositoryProvider).byId(id);
});

class ListingsRepository {
  const ListingsRepository(this._dio);

  final Dio _dio;

  Future<List<Listing>> search(ListingFilters filters) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/listings',
      queryParameters: filters.toQueryParameters(),
    );
    final payload = response.data;
    final rows = payload?['data'];

    if (rows is! List) {
      throw const FormatException('Format de réponse API inattendu.');
    }

    return rows
        .whereType<Map<String, dynamic>>()
        .map(Listing.fromJson)
        .toList(growable: false);
  }

  Future<Listing?> byId(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/listings/$id');
      final data = response.data?['data'];

      return data is Map<String, dynamic> ? Listing.fromJson(data) : null;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}