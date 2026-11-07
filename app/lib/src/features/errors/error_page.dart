import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/soutrali_theme.dart';
import 'app_error.dart';

/// Page d’erreur plein écran, déclinée par code (404, 403, 500, 503…) ou
/// inline dans un bloc de contenu (`compact`).
///
/// Elle est branchée à trois endroits :
/// - routeur : toute adresse inconnue affiche la page 404 ;
/// - détail d’annonce : une annonce retirée renvoie 404, une panne 500 ;
/// - liste « Annonces près de vous » : les mêmes écrans, en version locale.
class ErrorPage extends StatelessWidget {
  const ErrorPage({
    super.key,
    required this.error,
    this.location,
    this.onRetry,
    this.compact = false,
    this.titleOverride,
  });

  final AppError error;

  /// Adresse demandée, affichée pour aider à retrouver son chemin.
  final String? location;

  final VoidCallback? onRetry;

  /// Version sans échafaudage, à insérer dans une liste.
  final bool compact;

  final String? titleOverride;

  @override
  Widget build(BuildContext context) {
    final content = _ErrorContent(
      error: error,
      location: location,
      onRetry: onRetry,
      titleOverride: titleOverride,
      compact: compact,
    );

    if (compact) {
      return content;
    }

    return Scaffold(
      backgroundColor: SoutraliColors.ivory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({
    required this.error,
    required this.location,
    required this.onRetry,
    required this.titleOverride,
    required this.compact,
  });

  final AppError error;
  final String? location;
  final VoidCallback? onRetry;
  final String? titleOverride;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final heading = titleOverride ?? error.title;
    final canRetry = onRetry != null && error.canRetry;

    return ConstrainedBox(
      key: const ValueKey('error-page'),
      constraints: const BoxConstraints(maxWidth: 560),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 64 : 84,
              height: compact ? 64 : 84,
              decoration: BoxDecoration(
                color: SoutraliColors.paleGreen,
                shape: BoxShape.circle,
                border: Border.all(color: SoutraliColors.border),
              ),
              child: Icon(
                error.icon,
                size: compact ? 30 : 38,
                color: SoutraliColors.deepGreen,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              heading,
              key: const ValueKey('error-title'),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: compact ? 22 : 28),
            ),
            if (error.statusCode != null) ...[
              const SizedBox(height: 6),
              Text(
                'Erreur ${error.statusCode}',
                key: const ValueKey('error-code'),
                style: const TextStyle(
                  color: SoutraliColors.orangeText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: SoutraliColors.muted, fontSize: 15, height: 1.45),
            ),
            if (error.hint != null) ...[
              const SizedBox(height: 8),
              Text(
                error.hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SoutraliColors.muted, fontSize: 13),
              ),
            ],
            if (location != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: SoutraliColors.border),
                ),
                child: Text(
                  location!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: SoutraliColors.muted),
                ),
              ),
            ],
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: SoutraliColors.deepGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text('Retour à l’accueil'),
                ),
                if (canRetry)
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Réessayer'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
