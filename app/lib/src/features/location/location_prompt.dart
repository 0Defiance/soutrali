import 'package:flutter/material.dart';

import '../../theme/soutrali_theme.dart';
import 'geolocation.dart';

/// Fiche de localisation du démarrage : « Trier par distance ? ».
///
/// Elle n’apparaît qu’après la lecture d’une position par le navigateur et
/// la résolution de cette position par l’API. Tant que l’utilisateur n’a pas
/// confirmé, aucune coordonnée n’est utilisée pour trier les annonces.
///
/// Affichage : une **feuille ancrée en bas** plutôt qu’une boîte centrée —
/// elle laisse voir la page derrière, se ferme d’un glissement vers le bas
/// (ce qui vaut refus) et se place sous le pouce sur téléphone.
///
/// Depuis le 8 novembre 2026, la fiche ouvre sur un **plan de quartier**
/// dessiné (rues, îlots, lagune) où la position est épinglée : on comprend
/// d’un regard de quoi on parle, au lieu de lire un nom de commune seul.
class LocationPromptSheet extends StatelessWidget {
  const LocationPromptSheet({super.key, required this.place});

  final LocatedPlace place;

  static Future<LocationDecision> show(BuildContext context, LocatedPlace place) async {
    final decision = await showModalBottomSheet<LocationDecision>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: SoutraliColors.ink.withValues(alpha: 0.46),
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
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          key: const ValueKey('location-prompt'),
          decoration: const BoxDecoration(
            color: SoutraliColors.ivory,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, -8)),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            16 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: SoutraliColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                _NeighborhoodMap(
                  headline: _headline,
                  subtitle: _subtitle,
                  zone: place.zone,
                ),
                const SizedBox(height: 18),
                Text(
                  'Trier les annonces par distance ?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    height: 1.2,
                    color: SoutraliColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Votre navigateur nous a donné cette position. '
                  'Elle sert uniquement à afficher d’abord les annonces les plus proches de vous.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: SoutraliColors.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (place.accuracyMeters != null)
                      _Fact(icon: Icons.adjust_rounded, label: '± ${place.accuracyMeters} m'),
                    if (place.distanceMeters != null && place.distanceMeters! > 0)
                      _Fact(
                        icon: Icons.straighten_rounded,
                        label: 'à ${_distance(place.distanceMeters!)} du centre',
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const _Promises(),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    key: const ValueKey('location-confirm'),
                    style: FilledButton.styleFrom(
                      backgroundColor: SoutraliColors.orange,
                      foregroundColor: SoutraliColors.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(LocationDecision.confirmed),
                    icon: const Icon(Icons.near_me_rounded, size: 19),
                    label: const Text('Trier par distance'),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  key: const ValueKey('location-refuse'),
                  style: TextButton.styleFrom(foregroundColor: SoutraliColors.muted),
                  onPressed: () => Navigator.of(context).pop(LocationDecision.refused),
                  child: const Text('Rester sur tout Abidjan'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gps_fixed_rounded, size: 13, color: SoutraliColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      place.coordinatesLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: SoutraliColors.muted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
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

/// Plan de quartier stylisé : îlots, avenues et lagune dessinés au trait,
/// avec la position épinglée au centre et le nom du quartier sur le bas.
class _NeighborhoodMap extends StatelessWidget {
  const _NeighborhoodMap({
    required this.headline,
    required this.subtitle,
    this.zone,
  });

  final String headline;
  final String subtitle;
  final String? zone;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 186,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _MapPainter()),
            // Halo puis épingle : le regard tombe d’abord sur la position.
            const Center(child: _Pin()),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: SoutraliShadows.soft(alpha: 0.12, blur: 12, y: 3),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseDot(),
                    SizedBox(width: 7),
                    Text(
                      'Position détectée',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: SoutraliColors.deepGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (zone != null)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: SoutraliColors.ink.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    zone!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 44, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      SoutraliColors.forest.withValues(alpha: 0),
                      SoutraliColors.forest.withValues(alpha: 0.88),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Épingle blanche à ombre portée, posée sur le plan.
class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SoutraliColors.orange.withValues(alpha: 0.18),
            ),
            child: Center(
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: SoutraliShadows.brand(SoutraliColors.orange),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: SoutraliColors.orange,
                  size: 26,
                ),
              ),
            ),
          ),
          Container(
            width: 26,
            height: 7,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: SoutraliColors.ink.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trois promesses courtes, pour répondre à la question « qu’est-ce que je
/// gagne et qu’est-ce que je risque ? » avant de cliquer.
class _Promises extends StatelessWidget {
  const _Promises();

  static const _items = <(IconData, String)>[
    (Icons.sort_rounded, 'Les annonces de votre commune passent devant'),
    (Icons.straighten_rounded, 'La distance s’affiche sur chaque carte'),
    (Icons.lock_outline_rounded, 'Position non publiée, jamais partagée'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: SoutraliColors.paleGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SoutraliColors.forest.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          for (final (icon, label) in _items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(icon, size: 17, color: SoutraliColors.deepGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: SoutraliColors.ink,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Point orange qui signale une position « fraîche ».
class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SoutraliColors.orange,
        boxShadow: [
          BoxShadow(
            color: SoutraliColors.orange.withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
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
        border: Border.all(color: SoutraliColors.border),
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

/// Dessin du plan : lagune au sud, îlots réguliers, deux avenues traversantes
/// et la voie du quartier en orange. Tout est tracé au trait — aucun asset.
class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fond « terrain » : un vert-gris qui laisse les rues claires ressortir.
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFDCEBDF));

    // Lagune Ébrié, en bas à gauche.
    final lagoon = Path()
      ..moveTo(0, h * 0.74)
      ..quadraticBezierTo(w * 0.16, h * 0.64, w * 0.32, h * 0.8)
      ..quadraticBezierTo(w * 0.42, h * 0.92, w * 0.26, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(lagoon, Paint()..color = const Color(0xFFCFE5EF));

    // Îlots : trois rangées de pâtés de maisons, décalés d’une rangée à l’autre.
    final block = Paint()..color = const Color(0xFFC7DCCB);
    final blockEdge = Paint()
      ..color = const Color(0xFFB2CEB8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var row = 0; row < 3; row++) {
      final top = h * (0.1 + row * 0.28);
      final height = h * 0.16;
      for (var col = 0; col < 5; col++) {
        final left = w * (0.04 + col * 0.2) + (row.isOdd ? w * 0.05 : 0);
        if (left + w * 0.14 > w * 0.96) continue;
        final island = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, w * 0.14, height),
          const Radius.circular(5),
        );
        canvas
          ..drawRRect(island, block)
          ..drawRRect(island, blockEdge);
      }
    }

    // Avenues perpendiculaires : plus claires que les îlots, comme sur un plan.
    final avenue = Paint()
      ..color = const Color(0xFFF4FAF5)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    for (final y in [0.26, 0.54, 0.82]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * y), avenue);
    }
    for (final x in [0.24, 0.52, 0.8]) {
      canvas.drawLine(Offset(w * x, 0), Offset(w * x, h), avenue);
    }

    // La voie du quartier, en orange pâle, qui mène jusqu’à l’épingle.
    final road = Paint()
      ..color = SoutraliColors.orange.withValues(alpha: 0.5)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(-w * 0.02, h * 0.5)
      ..quadraticBezierTo(w * 0.28, h * 0.42, w * 0.5, h * 0.46)
      ..quadraticBezierTo(w * 0.74, h * 0.5, w * 1.02, h * 0.38);
    canvas.drawPath(path, road);

    // Un peu de végétation pour casser la géométrie.
    final tree = Paint()..color = const Color(0xFFA9CBAF);
    for (final spot in const [Offset(0.09, 0.72), Offset(0.86, 0.15), Offset(0.68, 0.86)]) {
      canvas.drawCircle(Offset(w * spot.dx, h * spot.dy), 9, tree);
      canvas.drawCircle(Offset(w * spot.dx + 12, h * spot.dy + 6), 6, tree);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => false;
}
