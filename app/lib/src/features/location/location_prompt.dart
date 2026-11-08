import 'package:flutter/material.dart';

import '../../theme/soutrali_theme.dart';
import 'geolocation.dart';

/// Fiche de localisation du démarrage : « Vous êtes ici ? ».
///
/// Elle n’apparaît qu’après la lecture d’une position par le navigateur et
/// la résolution de cette position par l’API. Tant que l’utilisateur n’a pas
/// confirmé, aucune coordonnée n’est utilisée pour trier les annonces.
///
/// Affichage : une **feuille ancrée en bas** plutôt qu’une boîte centrée —
/// elle laisse voir la page derrière, se ferme d’un glissement vers le bas
/// (ce qui vaut refus) et se place sous le pouce sur téléphone.
class LocationPromptSheet extends StatelessWidget {
  const LocationPromptSheet({super.key, required this.place});

  final LocatedPlace place;

  static Future<LocationDecision> show(BuildContext context, LocatedPlace place) async {
    final decision = await showModalBottomSheet<LocationDecision>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: SoutraliColors.ink.withValues(alpha: 0.42),
      builder: (context) => LocationPromptSheet(place: place),
    );

    return decision ?? LocationDecision.refused;
  }

  /// « Cocody — Angré », à défaut la ville, à défaut l’étiquette complète.
  String get _headline {
    final parts = [place.commune, place.quartier].whereType<String>().toList();

    if (parts.isNotEmpty) {
      return parts.join(' — ');
    }

    return place.city ?? place.label ?? 'Position détectée';
  }

  /// « Abidjan · Côte d’Ivoire », sans la partie déjà affichée en titre.
  String get _subtitle {
    final parts = [place.city, place.country].whereType<String>().toList();

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          key: const ValueKey('location-prompt'),
          decoration: BoxDecoration(
            color: SoutraliColors.ivory,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: SoutraliShadows.soft(),
          ),
          padding: EdgeInsets.fromLTRB(
            22,
            10,
            22,
            18 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: SoutraliColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        gradient: SoutraliGradients.forest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vous êtes ici ?',
                            style: theme.textTheme.titleLarge?.copyWith(fontSize: 21),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Votre navigateur nous a transmis cette position.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: SoutraliColors.muted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: SoutraliColors.paleGreen,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SoutraliColors.forest.withValues(alpha: 0.14)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headline,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: SoutraliColors.ink,
                        ),
                      ),
                      if (_subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          _subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: SoutraliColors.deepGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (place.accuracyMeters != null)
                            _Fact(
                              icon: Icons.adjust_rounded,
                              label: '± ${place.accuracyMeters} m',
                            ),
                          if (place.distanceMeters != null && place.distanceMeters! > 0)
                            _Fact(
                              icon: Icons.straighten_rounded,
                              label: 'à ${_distance(place.distanceMeters!)} du centre',
                            ),
                          if (place.zone != null)
                            _Fact(icon: Icons.map_outlined, label: place.zone!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed_rounded,
                            size: 14,
                            color: SoutraliColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              place.coordinatesLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: SoutraliColors.muted,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cette position sert seulement à classer les annonces les plus proches. '
                  'Elle n’est ni publiée ni partagée.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: SoutraliColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    key: const ValueKey('location-confirm'),
                    style: FilledButton.styleFrom(
                      backgroundColor: SoutraliColors.orange,
                      foregroundColor: SoutraliColors.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(context).pop(LocationDecision.confirmed),
                    icon: const Icon(Icons.check_rounded, size: 19),
                    label: const Text('C’est exact, trier par distance'),
                  ),
                ),
                TextButton(
                  key: const ValueKey('location-refuse'),
                  style: TextButton.styleFrom(foregroundColor: SoutraliColors.muted),
                  onPressed: () => Navigator.of(context).pop(LocationDecision.refused),
                  child: const Text('Ce n’est pas moi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _distance(int meters) =>
      meters < 1000 ? '$meters m' : '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Petit fait affiché en pastille dans la fiche (précision, écart, zone).
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: SoutraliColors.forest.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: SoutraliColors.deepGreen),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SoutraliColors.deepGreen,
            ),
          ),
        ],
      ),
    );
  }
}
