import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_repository.dart';
import '../discover/listings_repository.dart';

/// Aperçu d'un fil de discussion (liste Messagerie).
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.participantName,
    required this.unread,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'];
    final participant = json['participant'];
    final lastMessage = json['last_message'];

    return ConversationSummary(
      id: (json['id'] as num).toInt(),
      listingId: listing is Map<String, dynamic> ? (listing['id'] as num?)?.toInt() ?? 0 : 0,
      listingTitle: listing is Map<String, dynamic> ? listing['title'] as String? ?? '' : '',
      participantName: participant is Map<String, dynamic> ? participant['display_name'] as String? ?? 'Compte supprimé' : 'Compte supprimé',
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      lastMessage: lastMessage is Map<String, dynamic> ? lastMessage['body'] as String? : null,
      lastMessageAt: lastMessage is Map<String, dynamic> ? lastMessage['created_at'] as String? : null,
    );
  }

  final int id;
  final int listingId;
  final String listingTitle;
  final String participantName;
  final int unread;
  final String? lastMessage;
  final String? lastMessageAt;
}

/// Message d'un fil.
class ThreadMessage {
  const ThreadMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.isMine,
    required this.createdAt,
  });

  factory ThreadMessage.fromJson(Map<String, dynamic> json) => ThreadMessage(
        id: (json['id'] as num).toInt(),
        senderId: (json['sender_id'] as num?)?.toInt() ?? 0,
        body: json['body'] as String? ?? '',
        isMine: json['is_mine'] as bool? ?? false,
        createdAt: json['created_at'] as String?,
      );

  final int id;
  final int senderId;
  final String body;
  final bool isMine;
  final String? createdAt;
}

/// Fil complet ouvert (Messagerie : détail).
class ConversationThread {
  const ConversationThread({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.participantName,
    required this.messages,
  });

  factory ConversationThread.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'];
    final participant = json['participant'];
    final rawMessages = json['messages'];

    return ConversationThread(
      id: (json['id'] as num).toInt(),
      listingId: listing is Map<String, dynamic> ? (listing['id'] as num?)?.toInt() ?? 0 : 0,
      listingTitle: listing is Map<String, dynamic> ? listing['title'] as String? ?? '' : '',
      participantName: participant is Map<String, dynamic> ? participant['display_name'] as String? ?? '' : '',
      messages: rawMessages is List
          ? rawMessages.whereType<Map<String, dynamic>>().map(ThreadMessage.fromJson).toList(growable: false)
          : const [],
    );
  }

  final int id;
  final int listingId;
  final String listingTitle;
  final String participantName;
  final List<ThreadMessage> messages;
}

/// Liste des fils + total des messages non lus.
class ConversationsSnapshot {
  const ConversationsSnapshot({required this.items, required this.unreadTotal});

  const ConversationsSnapshot.empty() : items = const [], unreadTotal = 0;

  final List<ConversationSummary> items;
  final int unreadTotal;
}

class MessagingRepository {
  const MessagingRepository(this._dio);

  final Dio _dio;

  Future<ConversationsSnapshot> conversations() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/conversations');
    final data = response.data?['data'];

    return ConversationsSnapshot(
      items: data is List
          ? data.whereType<Map<String, dynamic>>().map(ConversationSummary.fromJson).toList(growable: false)
          : const [],
      unreadTotal: (response.data?['unread_total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<ConversationThread> open(int conversationId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/conversations/$conversationId');

    return ConversationThread.fromJson(response.data!);
  }

  /// Démarre (ou reprend) un fil autour d'une annonce ; renvoie son identifiant.
  Future<int> start({required int listingId, required String message}) async {
    await prepareCsrf(_dio);

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/listings/$listingId/conversations',
      data: {'message': message},
    );

    return (response.data?['id'] as num?)?.toInt() ?? 0;
  }

  Future<void> send({required int conversationId, required String body}) async {
    await prepareCsrf(_dio);
    await _dio.post<Map<String, dynamic>>('/api/v1/conversations/$conversationId/messages', data: {'body': body});
  }
}

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => MessagingRepository(ref.watch(dioProvider)),
);

/// Fils de l'utilisateur courant. Renvoie une liste vide pour un visiteur
/// (aucune requête réseau), et se rafraîchit automatiquement après connexion.
final conversationsProvider = FutureProvider<ConversationsSnapshot>((ref) async {
  final auth = ref.watch(authProvider);

  if (auth.value == null) {
    return const ConversationsSnapshot.empty();
  }

  return ref.watch(messagingRepositoryProvider).conversations();
});

/// Détail d'un fil (`/messagerie/{id}`).
final threadProvider = FutureProvider.family<ConversationThread, int>(
  (ref, conversationId) => ref.watch(messagingRepositoryProvider).open(conversationId),
);
