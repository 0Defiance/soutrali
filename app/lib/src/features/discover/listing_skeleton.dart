import 'package:flutter/material.dart';

import '../../theme/soutrali_theme.dart';

/// Grille de chargement des « Annonces près de vous ».
///
/// Pendant l’appel à l’API, l’écran montre des cartes fantômes à la forme
/// exacte des vraies annonces, animées par un reflet qui balaie la page
/// (7 nov. 2026). L’utilisateur voit immédiatement ce qui arrive, au lieu
/// d’un rond qui tourne sur une page vide.
class ListingSkeletonGrid extends StatelessWidget {
  const ListingSkeletonGrid({
    super.key,
    required this.columns,
    this.cardCount = 6,
    this.padding = const EdgeInsets.fromLTRB(40, 8, 40, 48),
  });

  final int columns;
  final int cardCount;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid.builder(
        itemCount: cardCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 272,
        ),
        itemBuilder: (context, index) => ListingSkeletonCard(
          key: ValueKey('listing-skeleton-$index'),
        ),
      ),
    );
  }
}

/// Une carte fantôme : mêmes repères visuels qu’une annonce (étiquettes,
/// titre, description, commune, catégorie).
class ListingSkeletonCard extends StatefulWidget {
  const ListingSkeletonCard({super.key});

  @override
  State<ListingSkeletonCard> createState() => _ListingSkeletonCardState();
}

class _ListingSkeletonCardState extends State<ListingSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Reflet qui traverse la carte de gauche à droite.
  Widget _shimmer({required double height, double? width, double radius = 8}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final position = _controller.value * 3 - 1.5;

        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(position - 1, 0),
              end: Alignment(position + 1, 0),
              colors: const [
                Color(0xFFEDF1EA),
                Color(0xFFF7FAF4),
                Color(0xFFEDF1EA),
              ],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SoutraliColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bandeau supérieur : la place du futur dégradé de service.
          Container(
            height: 82,
            width: double.infinity,
            color: const Color(0xFFF1F4EE),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _shimmer(height: 22, width: 74, radius: 999),
                const SizedBox(width: 7),
                _shimmer(height: 22, width: 84, radius: 999),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmer(height: 16),
                  const SizedBox(height: 8),
                  _shimmer(height: 16, width: 210),
                  const SizedBox(height: 14),
                  _shimmer(height: 11),
                  const SizedBox(height: 7),
                  _shimmer(height: 11, width: 160),
                  const Spacer(),
                  _shimmer(height: 12, width: 120),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _shimmer(height: 12)),
                      const SizedBox(width: 24),
                      _shimmer(height: 12, width: 46),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
