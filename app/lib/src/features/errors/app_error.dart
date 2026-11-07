import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Nature d’une erreur telle que l’utilisateur doit la comprendre.
///
/// Chaque code HTTP courant a sa propre page (7 nov. 2026) : un 404 n’est
/// pas un 500, et une coupure réseau ne doit pas être présentée comme une
/// panne du service.
enum AppErrorKind { notFound, forbidden, rateLimited, serverError, unavailable, offline, unknown }

class AppError {
  const AppError({
    required this.kind,
    required this.title,
    required this.message,
    required this.icon,
    this.statusCode,
    this.hint,
    this.canRetry = true,
  });

  final AppErrorKind kind;
  final String title;
  final String message;
  final IconData icon;
  final int? statusCode;
  final String? hint;
  final bool canRetry;

  /// Erreur correspondant à un code HTTP, ou `null` s’il est inconnu.
  static AppError? fromStatus(int? status) {
    return switch (status) {
      404 => const AppError(
          kind: AppErrorKind.notFound,
          statusCode: 404,
          title: 'Page introuvable',
          message: 'L’adresse demandée n’existe pas, ou le contenu a été retiré par son auteur.',
          hint: 'Vérifiez l’adresse, ou revenez aux annonces.',
          icon: Icons.travel_explore_outlined,
          canRetry: false,
        ),
      403 => const AppError(
          kind: AppErrorKind.forbidden,
          statusCode: 403,
          title: 'Accès refusé',
          message: 'Vous n’avez pas les droits nécessaires pour consulter cette page.',
          icon: Icons.lock_outline,
          canRetry: false,
        ),
      429 => const AppError(
          kind: AppErrorKind.rateLimited,
          statusCode: 429,
          title: 'Trop de demandes',
          message: 'Trop de requêtes ont été envoyées en peu de temps. Patientez un instant avant de réessayer.',
          icon: Icons.hourglass_empty,
        ),
      500 => const AppError(
          kind: AppErrorKind.serverError,
          statusCode: 500,
          title: 'Le serveur a rencontré un problème',
          message: 'La demande n’a pas pu être traitée. Vos données ne sont pas perdues : réessayez dans un instant.',
          icon: Icons.build_outlined,
        ),
      502 || 504 => const AppError(
          kind: AppErrorKind.unavailable,
          statusCode: 502,
          title: 'Le service ne répond pas',
          message: 'Le serveur met trop de temps à répondre. Réessayez dans quelques instants.',
          icon: Icons.cloud_off_outlined,
        ),
      503 => const AppError(
          kind: AppErrorKind.unavailable,
          statusCode: 503,
          title: 'Service momentanément indisponible',
          message: 'Soutrali est en maintenance ou reçoit trop de visites. Revenez dans quelques minutes.',
          icon: Icons.wifi_tethering_off_outlined,
        ),
      _ => null,
    };
  }

  /// Erreur réseau (pas de réponse du serveur) : la plus fréquente en
  /// connexion mobile, elle mérite son propre écran.
  static const network = AppError(
    kind: AppErrorKind.offline,
    title: 'Connexion impossible',
    message: 'Impossible de joindre Soutrali. Vérifiez votre connexion internet, puis réessayez.',
    hint: 'Une connexion faible suffit parfois : patientez quelques secondes.',
    icon: Icons.wifi_off_rounded,
  );

  static const unknown = AppError(
    kind: AppErrorKind.unknown,
    title: 'Une erreur inattendue est survenue',
    message: 'Quelque chose s’est mal passé de notre côté. Vous pouvez réessayer ou revenir à l’accueil.',
    icon: Icons.error_outline,
  );

  /// Traduit une exception remontée par l’API.
  factory AppError.fromException(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;

      if (status != null && status >= 400) {
        return fromStatus(status) ??
            AppError(
              kind: AppErrorKind.serverError,
              statusCode: status,
              title: 'La demande a échoué',
              message: 'Le serveur a répondu par une erreur ($status). Réessayez dans un instant.',
              icon: Icons.build_outlined,
            );
      }

      return network;
    }

    return unknown;
  }
}
