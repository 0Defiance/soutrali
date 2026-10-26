import 'package:flutter/material.dart';

import 'soutrali_theme.dart';

/// Motifs interactifs partagés par tous les écrans Soutrali.
///
/// Deux règles tiennent l’ensemble du dispositif :
///
/// 1. **Aucune animation infinie.** Une boucle empêcherait `pumpAndSettle`
///    de se poser et casserait la suite de tests : tout mouvement est soit
///    déclenché à la construction (entrée finie), soit piloté par le pointeur
///    — immobile au repos.
/// 2. **Charte graphique respectée (§15).** Vert, orange, ivoire et encre
///    restent les seules couleurs : les motifs sont des textures de fond à
///    faible opacité, jamais des éléments qui rivalisent avec le texte.

/// Ambiance d’un motif : adapte les valeurs du peintre au fond sur lequel
/// il se pose (ivoire, dégradé de marque, vert profond).
enum MotifStyle {
  /// Sur fond clair (ivoire, pâle vert).
  light,

  /// Sur le dégradé vert du volet de marque.
  brand,

  /// Sur le vert profond (pied de page).
  dark,
}

/// Calque de fond réactif : grille de points qui s’éclairent près du
/// pointeur, halos en parallaxe et lueur sous le curseur.
///
/// Le calque est décoratif : il se place **sous** le contenu dans un
/// `Stack`, qui reçoit donc les taps en priorité. Le `MouseRegion` entoure
/// l’ensemble, si bien que le survol est suivi même au-dessus des zones
/// vides (le `CustomPaint` y prend le hit-test, le texte non).
class InteractiveMotif extends StatefulWidget {
  const InteractiveMotif({
    super.key,
    required this.child,
    this.style = MotifStyle.light,
    this.density = 34,
    this.opacity = 1,
  });

  final Widget child;
  final MotifStyle style;

  /// Espacement, en pixels, de la grille de points.
  final double density;

  /// Intensité générale du motif (0 à 1).
  final double opacity;

  @override
  State<InteractiveMotif> createState() => _InteractiveMotifState();
}

class _InteractiveMotifState extends State<InteractiveMotif> {
  /// Position brute du pointeur dans la section ; `Offset.zero` = au repos.
  final ValueNotifier<Offset> _target = ValueNotifier<Offset>(Offset.zero);

  Size _size = Size.zero;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  void _track(Offset local) {
    if (_size == Size.zero) return;
    // Coordonnées normalisées (-1 à 1) : le peintre les convertit en
    // déplacement relatif, le motif reste ainsi juste à toute échelle.
    _target.value = Offset(
      (local.dx / _size.width) * 2 - 1,
      (local.dy / _size.height) * 2 - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => _track(event.localPosition),
      onHover: (event) => _track(event.localPosition),
      onExit: (_) => _target.value = Offset.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;

          return Stack(
            children: [
              Positioned.fill(
                // Seul ce sous-arbre se reconstruit au mouvement du
                // pointeur : le contenu n’est jamais repeint pour rien.
                child: ValueListenableBuilder<Offset>(
                  valueListenable: _target,
                  builder: (context, target, _) => TweenAnimationBuilder<Offset>(
                    tween: Tween(begin: Offset.zero, end: target),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    builder: (context, shift, _) => RepaintBoundary(
                      child: CustomPaint(
                        painter: MotifPainter(
                          shift: shift,
                          style: widget.style,
                          density: widget.density,
                          opacity: widget.opacity,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          );
        },
      ),
    );
  }
}

/// Peintre du motif : grille de points, halos en parallaxe et lueur du
/// pointeur. Tout est recalculé à partir de la taille du calque et du
/// déplacement courant — donc sans tick propre.
class MotifPainter extends CustomPainter {
  const MotifPainter({
    required this.shift,
    this.style = MotifStyle.light,
    this.density = 34,
    this.opacity = 1,
  });

  /// Déplacement du pointeur, normalisé de -1 à 1.
  final Offset shift;
  final MotifStyle style;
  final double density;
  final double opacity;

  (Color, Color) get _palette => switch (style) {
        MotifStyle.light => (SoutraliColors.green, SoutraliColors.orange),
        MotifStyle.brand => (Colors.white, SoutraliColors.orange),
        MotifStyle.dark => (Colors.white, SoutraliColors.orange),
      };

  double get _baseDotAlpha => switch (style) {
        MotifStyle.light => 0.16,
        MotifStyle.brand => 0.20,
        MotifStyle.dark => 0.14,
      };

  double get _glowAlpha => switch (style) {
        MotifStyle.light => 0.10,
        MotifStyle.brand => 0.16,
        MotifStyle.dark => 0.12,
      };

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    final (dot, accent) = _palette;
    final glow = Offset(
      size.width / 2 + shift.dx * size.width * 0.30,
      size.height / 2 + shift.dy * size.height * 0.30,
    );
    final reach = size.shortestSide * 0.9;

    // Halos de fond, chacun avec sa propre profondeur de parallaxe.
    final halos = <(Offset, double, Color, double)>[
      (Offset(size.width * 0.86, size.height * 0.16), 0.5, accent, 0.16),
      (Offset(size.width * 0.10, size.height * 0.88), 0.4, dot, 0.14),
      (Offset(size.width * 0.58, size.height * 1.02), 0.7, dot, 0.10),
    ];

    for (var index = 0; index < halos.length; index++) {
      final (anchor, depth, color, alpha) = halos[index];
      final center = anchor + Offset(shift.dx, shift.dy) * (28 * depth);
      final radius = size.shortestSide * depth + 40;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha * opacity),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // Grille de points : grossis et éclaircis à proximité du curseur.
    final dotPaint = Paint();
    for (var x = density / 2; x < size.width; x += density) {
      for (var y = density / 2; y < size.height; y += density) {
        final point = Offset(x, y);
        final distance = (point - glow).distance;
        final nearness = (1 - distance / reach).clamp(0.0, 1.0);
        final eased = nearness * nearness;

        dotPaint.color = dot.withValues(
          alpha: (_baseDotAlpha + eased * 0.34) * opacity,
        );
        canvas.drawCircle(point, 1.6 + eased * 1.7, dotPaint);
      }
    }

    // Lueur douce sous le pointeur.
    final haloRadius = size.shortestSide * 0.42;
    canvas.drawCircle(
      glow,
      haloRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: _glowAlpha * opacity),
            accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: glow, radius: haloRadius)),
    );
  }

  @override
  bool shouldRepaint(MotifPainter oldDelegate) =>
      oldDelegate.shift != shift ||
      oldDelegate.style != style ||
      oldDelegate.density != density ||
      oldDelegate.opacity != opacity;
}

/// Entrée en fondu-glissé, décalée par `delay` : animation finie qui se
/// rejoue si le délai change, jamais de boucle.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.delay = 0, this.rise = 12});

  final Widget child;
  final int delay;
  final double rise;

  @override
  Widget build(BuildContext context) {
    final total = 480 + delay;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * rise), child: child),
      ),
      child: child,
    );
  }
}

/// Survol et appui : la carte se relève, s’assoit sous le doigt et peut
/// prévenir son contenu (`onHoverChanged`) pour ajuster bordure ou icône.
///
/// Le mouvement est piloté par un contrôleur **fini** (`animateTo` à 1 ou
/// 0) : il n’y a donc aucune image planifiée tant que la souris ne bouge
/// pas.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.rise = 6,
    this.scale = 1.0,
    this.pressScale = 0.985,
    this.onHoverChanged,
    this.cursor = SystemMouseCursors.click,
  });

  final Widget child;
  final double rise;
  final double scale;
  final double pressScale;
  final ValueChanged<bool>? onHoverChanged;
  final MouseCursor cursor;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  bool _hovered = false;
  bool _pressed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setHover(bool hovered) {
    if (hovered == _hovered) return;
    _hovered = hovered;
    widget.onHoverChanged?.call(hovered);

    if (hovered) {
      _controller.animateTo(1, curve: Curves.easeOutCubic);
    } else {
      _controller.animateBack(0, curve: Curves.easeOutCubic);
    }
    // L’état ne pilote que la pression : le survol vit dans le contrôleur.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? widget.pressScale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -widget.rise * _controller.value),
              child: child,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Filet d’accent qui se déploie à l’arrivée d’un titre de section :
/// sert de repère visuel entre l’en-tête et le contenu.
class AnimatedAccent extends StatelessWidget {
  const AnimatedAccent({
    super.key,
    this.color = SoutraliColors.orange,
    this.width = 56,
    this.height = 5,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: width * value,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      );
}