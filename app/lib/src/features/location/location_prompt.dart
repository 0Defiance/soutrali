import 'package:flutter/material.dart';

import '../../theme/soutrali_theme.dart';
import 'geolocation.dart';

/// Popup du démarrage : « Nous vous situons ici — est-ce exact ? ».
///
/// Elle n’apparaît qu’après la lecture d’une position par le navigateur et
/// la résolution de cette position par l’API. Tant que l’utilisateur n’a pas
/// confirmé, aucune coordonnée n’est utilisée pour trier les annonces.
class LocationPromptDialog extends StatelessWidget {
  const LocationPromptDialog({super.key, required this.place});

  final LocatedPlace place;

  static Future<LocationDecision> show(BuildContext context, LocatedPlace place) async {
    final decision = await showDialog<LocationDecision>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LocationPromptDialog(place: place),
    );

    return decision ?? LocationDecision.refused;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      key: const ValueKey('location-prompt'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: SoutraliColors.paleGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location, color: SoutraliColors.deepGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nous vous situons',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'L’équipe Soutrali vous localise au :',
                style: theme.textTheme.bodyMedium?.copyWith(color: SoutraliColors.muted),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SoutraliColors.ivory,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SoutraliColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Line(label: 'Pays', value: place.country ?? '—'),
                    _Line(label: 'Ville', value: place.city ?? '—'),
                    _Line(label: 'Commune', value: place.commune ?? '—'),
                    _Line(label: 'Quartier', value: place.quartier ?? '—'),
                    if (place.zone != null) _Line(label: 'Zone', value: place.zone!),
                    _Line(
                      label: 'Coordonnées GPS',
                      value: place.coordinatesLabel,
                      mono: true,
                    ),
                    if (place.accuracyMeters != null)
                      _Line(
                        label: 'Précision',
                        value: '± ${place.accuracyMeters} m',
                      ),
                    if (place.distanceMeters != null && place.distanceMeters! > 0)
                      _Line(
                        label: 'Écart au centre du quartier',
                        value: '${(place.distanceMeters! / 1000).toStringAsFixed(1)} km',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ces coordonnées servent uniquement à classer les annonces les plus proches. '
                'Elles ne sont pas publiées ni partagées.',
                style: TextStyle(fontSize: 12.5, color: SoutraliColors.muted, height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('location-refuse'),
                      onPressed: () => Navigator.of(context).pop(LocationDecision.refused),
                      child: const Text('Ce n’est pas moi'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('location-confirm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: SoutraliColors.orange,
                        foregroundColor: SoutraliColors.ink,
                      ),
                      onPressed: () => Navigator.of(context).pop(LocationDecision.confirmed),
                      child: const Text('C’est exact'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: SoutraliColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: SoutraliColors.ink,
                fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
