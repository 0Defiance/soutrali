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
    this.publishAt,
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
      publishAt: DateTime.tryParse(json['publish_at'] as String? ?? ''),
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

  /// Date de publication programmée (`null` = publiée immédiatement).
  final DateTime? publishAt;
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

/// Compte bloqué par l’utilisateur connecté (blocages, T-14).
class BlockedUser {
  const BlockedUser({required this.id, required this.displayName});

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        id: (json['id'] as num).toInt(),
        displayName: json['display_name'] as String? ?? '',
      );

  final int id;
  final String displayName;
}

/// Canal de contact du profil (F-02) : le type est limité à
/// EMAIL / TELEPHONE / WHATSAPP côté API, la visibilité est choisie
/// par l’auteur et le canal n’est exposé que s’il est visible.
class ContactChannel {
  const ContactChannel({
    required this.type,
    required this.label,
    required this.value,
    required this.visibleToMembers,
    this.id,
  });

  factory ContactChannel.fromJson(Map<String, dynamic> json) => ContactChannel(
        id: (json['id'] as num?)?.toInt(),
        type: json['type'] as String? ?? '',
        label: json['label'] as String? ?? json['type'] as String? ?? '',
        value: json['value'] as String? ?? '',
        visibleToMembers: json['visible_to_members'] as bool? ?? false,
      );

  final int? id;
  final String type;
  final String label;
  final String value;
  final bool visibleToMembers;
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
    this.publishAt,
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

  /// Publication programmée (facultative) : mise en ligne différée.
  final DateTime? publishAt;

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
        if (publishAt != null) 'publish_at': publishAt!.toIso8601String(),
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

  /// Mettre en ligne immédiatement une annonce programmée.
  Future<MyListing> publishNow(int listingId) async {
    await prepareCsrf(_dio);
    final response = await _dio.post<Map<String, dynamic>>('/api/v1/listings/$listingId/publish');

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

  /// Comptes bloqués par l’utilisateur connecté (T-14).
  Future<List<BlockedUser>> blockedUsers() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/me/blocks');
    final data = response.data?['data'];

    return data is List
        ? data.whereType<Map<String, dynamic>>().map(BlockedUser.fromJson).toList(growable: false)
        : const [];
  }

  /// Bloquer un compte : la messagerie est désactivée dans les deux sens.
  Future<void> block(int userId) async {
    await prepareCsrf(_dio);
    await _dio.post<Map<String, dynamic>>('/api/v1/users/$userId/block');
  }

  /// Débloquer un compte (idempotent côté API).
  Future<void> unblock(int userId) async {
    await prepareCsrf(_dio);
    await _dio.delete<Map<String, dynamic>>('/api/v1/users/$userId/block');
  }

  /// Mes canaux de contact (F-02).
  Future<List<ContactChannel>> channels() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/me/channels');
    final data = response.data?['data'];

    return data is List
        ? data.whereType<Map<String, dynamic>>().map(ContactChannel.fromJson).toList(growable: false)
        : const [];
  }

  /// Créer ou mettre à jour un canal (unicité par type de canal).
  Future<void> saveChannel({
    required String type,
    required String value,
    required bool visibleToMembers,
  }) async {
    await prepareCsrf(_dio);
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/me/channels',
      data: {
        'type': type,
        'value': value,
        'visible_to_members': visibleToMembers,
      },
    );
  }

  Future<void> deleteChannel(int channelId) async {
    await prepareCsrf(_dio);
    await _dio.delete<Map<String, dynamic>>('/api/v1/me/channels/$channelId');
  }

  /// Canaux visibles de l’auteur d’une annonce (F-06) : réservé aux
  /// comptes connectés ; l’API répond 403 si le canal n’est pas
  /// disponible (annonce à soi, blocage) — listée vide dans ce cas.
  Future<List<ContactChannel>> listingChannels(int listingId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/listings/$listingId/contact-channels',
      );
      final data = response.data?['data'];

      return data is List
          ? data.whereType<Map<String, dynamic>>().map(ContactChannel.fromJson).toList(growable: false)
          : const [];
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 403 || status == 404) {
        return const [];
      }
      rethrow;
    }
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

/// Comptes que j’ai bloqués (visiteur : liste vide sans requête réseau).
final blockedUsersProvider = FutureProvider<List<BlockedUser>>((ref) async {
  final auth = ref.watch(authProvider);

  if (auth.value == null) {
    return const [];
  }

  return ref.watch(accountRepositoryProvider).blockedUsers();
});

/// Mes canaux de contact (visiteur : liste vide sans requête réseau).
final myChannelsProvider = FutureProvider<List<ContactChannel>>((ref) async {
  final auth = ref.watch(authProvider);

  if (auth.value == null) {
    return const [];
  }

  return ref.watch(accountRepositoryProvider).channels();
});

/// Canaux visibles de l’auteur d’une annonce : liste vide pour un
/// visiteur, sur 403 (blocage, propre annonce) ou sur 404.
final listingChannelsProvider = FutureProvider.family<List<ContactChannel>, int>((ref, listingId) async {
  final auth = ref.watch(authProvider);

  if (auth.value == null) {
    return const [];
  }

  return ref.watch(accountRepositoryProvider).listingChannels(listingId);
});
