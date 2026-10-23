import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_repository.dart';
import '../discover/listings_repository.dart';

/// Annonce vue par son auteur : statut et issue de clôture en plus.
class MyListing {
  const MyListing({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.nature,
    required this.status,
    required this.categoryId,
    required this.categoryName,
    required this.communeId,
    required this.communeName,
    this.closureOutcome,
    this.neighborhood,
    this.availability,
    this.budget,
    this.createdAt,
  });

  factory MyListing.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final commune = json['commune'];

    return MyListing(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'OFFRE',
      nature: json['nature'] as String? ?? 'BENEVOLE',
      status: json['status'] as String? ?? 'BROUILLON',
      closureOutcome: json['closure_outcome'] as String?,
      neighborhood: json['neighborhood'] as String?,
      availability: json['availability'] as String?,
      budget: json['budget'] is num ? (json['budget'] as num).toDouble() : double.tryParse('${json['budget']}'),
      categoryId: category is Map<String, dynamic> ? (category['id'] as num?)?.toInt() ?? 0 : 0,
      categoryName: category is Map<String, dynamic> ? category['name'] as String? ?? '' : '',
      communeId: commune is Map<String, dynamic> ? (commune['id'] as num?)?.toInt() ?? 0 : 0,
      communeName: commune is Map<String, dynamic> ? commune['name'] as String? ?? '' : '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  final int id;
  final String title;
  final String description;
  final String type;
  final String nature;
  final String status;
  final String? closureOutcome;
  final String? neighborhood;
  final String? availability;
  final double? budget;
  final int categoryId;
  final String categoryName;
  final int communeId;
  final String communeName;
  final DateTime? createdAt;
}

/// Signalement émis par l'utilisateur (suivi du statut, F-07).
class UserReport {
  const UserReport({
    required this.id,
    required this.reason,
    required this.status,
    required this.listingTitle,
    required this.createdAt,
  });

  factory UserReport.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'];

    return UserReport(
      id: (json['id'] as num).toInt(),
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? '',
      listingTitle: listing is Map<String, dynamic> ? listing['title'] as String? ?? '' : '',
      createdAt: json['created_at'] as String?,
    );
  }

  final int id;
  final String reason;
  final String status;
  final String listingTitle;
  final String? createdAt;
}

/// Données prêtes à publier ou à modifier (formulaire d'annonce).
class ListingDraft {
  const ListingDraft({
    required this.title,
    required this.description,
    required this.type,
    required this.nature,
    required this.categoryId,
    required this.communeId,
    this.neighborhood,
    this.availability,
    this.budget,
  });

  final String title;
  final String description;
  final String type;
  final String nature;
  final int categoryId;
  final int communeId;
  final String? neighborhood;
  final String? availability;
  final double? budget;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'type': type,
        'nature': nature,
        'category_id': categoryId,
        'commune_id': communeId,
        if (neighborhood != null && neighborhood!.trim().isNotEmpty) 'neighborhood': neighborhood!.trim(),
        if (availability != null && availability!.trim().isNotEmpty) 'availability': availability!.trim(),
        if (budget != null) 'budget': budget,
      };
}

class AccountRepository {
  const AccountRepository(this._dio);

  final Dio _dio;

  Future<List<MyListing>> myListings() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/me/listings');
    final data = response.data?['data'];

    return data is List
        ? data.whereType<Map<String, dynamic>>().map(MyListing.fromJson).toList(growable: false)
        : const [];
  }

  Future<MyListing> create(ListingDraft draft) async {
    await prepareCsrf(_dio);
    final response = await _dio.post<Map<String, dynamic>>('/api/v1/listings', data: draft.toJson());

    return MyListing.fromJson(response.data!);
  }

  Future<MyListing> update(int listingId, ListingDraft draft) async {
    await prepareCsrf(_dio);
    final response = await _dio.patch<Map<String, dynamic>>('/api/v1/listings/$listingId', data: draft.toJson());

    return MyListing.fromJson(response.data!);
  }

  Future<MyListing> close(int listingId, {required String outcome}) async {
    await prepareCsrf(_dio);
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/listings/$listingId/close',
      data: {'closure_outcome': outcome},
    );

    return MyListing.fromJson(response.data!);
  }

  Future<List<UserReport>> myReports() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/me/reports');
    final data = response.data?['data'];

    return data is List
        ? data.whereType<Map<String, dynamic>>().map(UserReport.fromJson).toList(growable: false)
        : const [];
  }

  Future<void> report(int listingId, {required String reason, String? details}) async {
    await prepareCsrf(_dio);
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/listings/$listingId/reports',
      data: {
        'reason': reason,
        if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
      },
    );
  }
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(dioProvider)),
);

/// Mes annonces (visiteur : liste vide sans requête réseau).
final myListingsProvider = FutureProvider<List<MyListing>>((ref) async {
  final auth = ref.watch(authProvider);

  if (auth.value == null) {
    return const [];
  }

  return ref.watch(accountRepositoryProvider).myListings();
});

/// Mes signalements (visiteur : liste vide sans requête réseau).
final myReportsProvider = FutureProvider<List<UserReport>>((ref) async {
  final auth = ref.watch(authProvider);

  if (auth.value == null) {
    return const [];
  }

  return ref.watch(accountRepositoryProvider).myReports();
});
