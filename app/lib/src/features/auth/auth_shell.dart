import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/motifs.dart';
import '../../theme/soutrali_theme.dart';

/// Habillage commun des écrans d’authentification (connexion, inscription) :
/// volet de marque animé à gauche sur grand écran, formulaire encarté à
/// droite sur fond ivoire. En largeur réduite, le volet de marque passe
/// en bandeau au-dessus du formulaire.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 940;
    final form = _FormPanel(title: title, subtitle: subtitle, footer: footer, child: child);

    return Scaffold(
      backgroundColor: SoutraliColors.ivory,
      body: wide
          ? Row(
              children: [
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(flex: 6, child: form),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const _BrandPanel(compact: true),
                  form,
                ],
              ),
            ),
    );
  }
}

/// Volet de marque : dégradé vert, logo sur pastille blanche, promesse et
/// trois repères d’entrée animés (apparition décalée).
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  static const _highlights = [
    (icon: Icons.handshake_outlined, title: 'Un réseau de proximité', detail: 'Des demandes et des offres à l’échelle de la commune.'),
    (icon: Icons.shield_outlined, title: 'Contact maîtrisé', detail: 'Vos coordonnées restent visibles que si vous le souhaitez.'),
    (icon: Icons.chat_bubble_outline, title: 'Messagerie intégrée', detail: 'Échangez sans jamais quitter Soutrali.'),
  ];

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          color: Colors.white,
          fontSize: compact ? 26 : 34,
        );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SoutraliColors.deepGreen, SoutraliColors.green],
        ),
      ),
      // Motif réactif : la grille suit le pointeur en parallaxe sous les
      // cercles décoratifs, et reste parfaitement immobile au repos.
      child: InteractiveMotif(
        style: MotifStyle.brand,
        density: 46,
        opacity: 0.85,
        child: Stack(
        children: [
          Positioned(
            top: compact ? -60 : -90,
            right: compact ? -70 : -110,
            child: _Blob(size: compact ? 190 : 260, color: Colors.white, opacity: 0.07),
          ),
          Positioned(
            bottom: compact ? -70 : -110,
            left: compact ? -60 : -80,
            child: _Blob(size: compact ? 170 : 230, color: SoutraliColors.orange, opacity: 0.22),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 24 : 52,
              vertical: compact ? 26 : 48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo sur pastille claire : lisible quel que soit le fond.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        'assets/brand/soutrali-logo.png',
                        width: compact ? 128 : 168,
                        height: compact ? 46 : 58,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      compact
                          ? 'L’entraide à porter de main, près de chez vous.'
                          : 'Un coup de main,\nprès de chez vous.',
                      style: headlineStyle,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Publiez un besoin, proposez vos compétences et trouvez '
                      'de l’aide dans votre commune, sans intermédiaire.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 34),
                      for (var index = 0; index < _highlights.length; index++)
                        _Reveal(
                          delay: 120 * index,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _HighlightLine(highlight: _highlights[index]),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _HighlightLine extends StatelessWidget {
  const _HighlightLine({required this.highlight});

  final ({IconData icon, String title, String detail}) highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(highlight.icon, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                highlight.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                highlight.detail,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cercle décoratif translucide du volet de marque.
class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      );
}

/// Apparition en fondu-glissé, décalée par `delay` (animation finie, sans
/// boucle) : l’écran se pose au lieu d’apparaître d’un bloc.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 480 + delay),
        curve: Interval(delay / (480 + delay), 1, curve: Curves.easeOutCubic),
        builder: (context, value, _) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
        ),
        child: child,
      );
}

/// Colonne de droite : retour, titre et formulaire dans une carte blanche.
class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;

    final panel = Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 40, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 460),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, (1 - value) * 18), child: _card(context)),
            ),
          ),
        ),
      ),
    );

    // En pile, la hauteur est bornée : le motif se peint derrière la
    // carte. En colonne défilante, la hauteur est infinie — on garde le
    // fond nu plutôt qu’un calque sans dimension.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedHeight
          ? InteractiveMotif(
              style: MotifStyle.light,
              density: 40,
              opacity: 0.75,
              child: panel,
            )
          : panel,
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compactPadding(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SoutraliColors.border),
        boxShadow: [
          BoxShadow(
            color: SoutraliColors.ink.withValues(alpha: 0.07),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Retour'),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: SoutraliColors.muted)),
          const SizedBox(height: 22),
          child,
          const SizedBox(height: 14),
          footer,
        ],
      ),
    );
  }

  double compactPadding(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 560 ? 22 : 32;
}
