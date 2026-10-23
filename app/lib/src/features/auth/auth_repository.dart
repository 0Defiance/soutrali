import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../discover/listings_repository.dart';

/// Compte connecté tel que renvoyé par `GET /api/v1/me`.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.role,
    this.communeId,
    this.communeName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final commune = json['commune'];

    return AuthUser(
      id: (json['id'] as num).toInt(),
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String?,
      communeId: commune is Map<String, dynamic> ? (commune['id'] as num?)?.toInt() : null,
      communeName: commune is Map<String, dynamic> ? commune['name'] as String? : null,
    );
  }

  final int id;
  final String displayName;
  final String email;
  final String? role;
  final int? communeId;
  final String? communeName;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// Récupère le jeton CSRF JSON (`GET /api/v1/csrf-token`) avant chaque
/// mutation : le jeton change après une inscription ou une connexion.
Future<void> prepareCsrf(Dio dio) async {
  final response = await dio.get<Map<String, dynamic>>('/api/v1/csrf-token');
  final token = response.data?['token'];

  if (token is String && token.isNotEmpty) {
    dio.options.headers['X-CSRF-TOKEN'] = token;
  }
}

/// Message d'exploitable depuis une erreur 422 de l'API (champ par champ,
/// sinon le message général).
String apiErrorMessage(Object error, {String fallback = 'Une erreur est survenue. Vérifiez votre saisie.'}) {
  if (error is! DioException) {
    return fallback;
  }

  final data = error.response?.data;

  if (data is Map<String, dynamic>) {
    final errors = data['errors'];

    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          return value.first as String;
        }
      }
    }

    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
  }

  if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout) {
    return 'Le service est momentanément indisponible. Réessayez dans un instant.';
  }

  return fallback;
}

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  /// Session courante, ou `null` si personne n'est connecté (401).
  Future<AuthUser?> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/me');
      final user = response.data?['user'];

      return user is Map<String, dynamic> ? AuthUser.fromJson(user) : null;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        return null;
      }
      rethrow;
    }
  }

  Future<AuthUser> login({required String email, required String password}) async {
    await prepareCsrf(_dio);

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/login',
      data: {'email': email, 'password': password},
    );

    return AuthUser.fromJson(response.data!['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> register({
    required String displayName,
    required String email,
    required String password,
    int? communeId,
  }) async {
    await prepareCsrf(_dio);

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/register',
      data: {
        'display_name': displayName,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'commune_id': ?communeId,
      },
    );

    return AuthUser.fromJson(response.data!['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await prepareCsrf(_dio);
    await _dio.post<Map<String, dynamic>>('/api/v1/logout');
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

/// Session courante de l'application : `null` = visiteur.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() => ref.read(authRepositoryProvider).me();

  Future<void> login({required String email, required String password}) async {
    final user = await ref.read(authRepositoryProvider).login(email: email, password: password);
    state = AsyncData(user);
  }

  Future<AuthUser> register({
    required String displayName,
    required String email,
    required String password,
    int? communeId,
  }) async {
    final user = await ref.read(authRepositoryProvider).register(
      displayName: displayName,
      email: email,
      password: password,
      communeId: communeId,
    );
    state = AsyncData(user);

    return user;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// Déconnecte localement sans appel réseau (si le serveur est injoignable).
  void resetLocally() => state = const AsyncData(null);
}

final authProvider = AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
